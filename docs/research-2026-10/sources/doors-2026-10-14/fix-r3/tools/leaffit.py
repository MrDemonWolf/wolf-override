"""Fix round 3 (R3-2): fits each swing leaf's door light (gain, reach; true Lambert, no wrap) and exposure so
that, open, the head by the hinge reads 0.85x the reveal it hangs on, the free edge low stays at or below
the wall beside it, and the shut leaf stays at or below its wall (r2's N3). Inputs: leafcheck.py's r2
measurements (reveal, wall at the low rows) and measure4's wall at the door rows; the screen/model scale
c per leaf is the r2 head measurement over leaflight.py's model at r2's settings."""
import sys, copy, json, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import leaflight as LL
import numpy as np


def light(p, nrm, lights, door_gain=1.0, only=None, door_wrap=0.0):
    out = LL.AMB.copy()
    for i, (L, col, reach, down) in enumerate(lights):
        d = np.array(L) - p; dist = np.linalg.norm(d); dr = d / dist
        ndl = np.clip(dr @ nrm, 0, 1)
        if ndl <= 0:
            continue
        w = door_wrap if i == 0 else LL.WRAP
        ndl = w + (1 - w) * ndl
        fall = 1 / (1 + (dist / reach) ** 2)
        if down > 0:
            below = np.clip((dr[1] + 0.35) / 1.35, 0, 1); fall *= 0.04 + 0.96 * below ** down
        out = out + np.array(col) * ndl * fall * (door_gain if i == 0 else 1.0)
    return out


R2 = {"records-exit": dict(rev=0.0637, wall_low=0.0295, wall=0.0082, head=0.0099),
      "records-entry": dict(rev=0.0437, wall_low=0.0200, wall=0.0097, head=0.0132),
      "junction-entry": dict(rev=0.0983, wall_low=0.0077, wall=0.0083, head=0.0141)}

if __name__ == "__main__":
    out = {}
    for nm, D in LL.LEAVES.items():
        M = R2[nm]
        c = M["head"] / LL.zone_lum(D, 1.0, 1.0, D["e"], "head")
        LL.light = light
        best = None
        for reach in (0.3, 0.4, 0.5, 0.6, 0.8):
            for e_f in (0.3, 0.4, 0.5, 0.6, 0.8, 1.0):
                DD = copy.deepcopy(D); DD["L"][0][2] = reach; e = D["e"] * e_f
                h0 = LL.zone_lum(DD, 1.0, 0.0, e, "head"); h1 = LL.zone_lum(DD, 1.0, 1.0, e, "head")
                k = (0.85 * M["rev"] / c - h0) / max(h1 - h0, 1e-9)
                if k <= 0:
                    continue
                low = LL.zone_lum(DD, 1.0, k, e, "low") * c / M["wall_low"]
                shut = LL.zone_lum(DD, 0.0, k, e, "all") * c / M["wall"]
                score = max(low, shut)
                if best is None or score < best["score"]:
                    best = dict(score=round(score, 3), reach=reach, exposure=round(e, 4), door_gain=round(float(k), 2), low_over_wall=round(low, 2), shut_over_wall=round(shut, 2), c=round(c, 3))
        LL.light = LL.__dict__["light"]
        out[nm] = best
        print(nm, best)
        import importlib; importlib.reload(LL)
    json.dump(out, open(sys.argv[1], "w"), indent=1) if len(sys.argv) > 1 else None
