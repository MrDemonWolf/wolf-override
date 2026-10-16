"""Fix round 3 (R3-2): SwingLeaf's per-vertex light, replicated (swing_leaf.gd shade, ROWS, two columns), split
into the door light (lights[0]) and the rest, at the zones leafcheck.py measures: the head by the hinge
(top 4-22 % of the leaf, hinge column) and the free edge low (bottom 4-22 %, free column), open and shut.
Screen linear luminance goes as exposure x light (the vertex colour multiplies the art in sRGB)."""
import numpy as np
ROWS = np.array([0.0, 0.2, 0.45, 0.7, 0.88, 1.0])
AMB = np.array([0.020, 0.032, 0.042]); PAINT = np.array([0.18, 0.195, 0.235]); WRAP = 0.06
W = np.array([0.2126, 0.7152, 0.0722])
LEAVES = {
    "records-exit": dict(h=(21.85451, 0, 0.43655), u=(-0.291329, 0, 0.956623), n=(0.956623, 0, 0.291329), e=0.17,
                         L=[[(21.9043, 2.8, -0.0291), (0.817, 0.9025, 0.95), 1.4, 2.0], [(15.0056, 5.5765, 4.3), (0.648, 0.837, 0.9), 3.2, 1.5], [(20.0, 0.1, -3.0), (0.165, 0.225, 0.255), 5.0, 0.0]]),
    "records-entry": dict(h=(1.89549, 0, 0.43655), u=(0.291329, 0, 0.956623), n=(-0.956623, 0, 0.291329), e=0.25,
                          L=[[(1.8457, 2.8, -0.0291), (0.817, 0.9025, 0.95), 1.4, 2.0], [(3.6013, 5.5765, 4.3), (0.648, 0.837, 0.9), 3.2, 1.5], [(3.75, 0.1, -3.0), (0.165, 0.225, 0.255), 5.0, 0.0]]),
    "junction-entry": dict(h=(0.89597, 0, 0.43639), u=(0.292372, 0, 0.956305), n=(-0.956305, 0, 0.292372), e=0.33,
                           L=[[(0.8456, 2.8, -0.0292), (0.817, 0.9025, 0.95), 1.4, 2.0], [(1.9461, 5.237, 4.2), (0.682, 0.99, 1.1), 3.4, 1.5], [(2.75, 0.1, -3.0), (0.055, 0.075, 0.085), 4.0, 0.0]]),
}


def srgb(c):
    c = np.clip(c, 0, 1)
    return np.where(c <= 0.0031308, c * 12.92, 1.055 * c ** (1 / 2.4) - 0.055)


def lin(c):
    c = np.clip(c, 0, 1)
    return np.where(c <= 0.04045, c / 12.92, ((c + 0.055) / 1.055) ** 2.4)


def light(p, nrm, lights, door_gain=1.0, only=None):
    out = AMB.copy() if only in (None, "rest") else np.zeros(3)
    for i, (L, col, reach, down) in enumerate(lights):
        if only == "door" and i != 0 or only == "rest" and i == 0:
            continue
        d = np.array(L) - p; dist = np.linalg.norm(d); dr = d / dist
        ndl = np.clip(dr @ nrm, 0, 1)
        if ndl <= 0:
            continue
        ndl = WRAP + (1 - WRAP) * ndl
        fall = 1 / (1 + (dist / reach) ** 2)
        if down > 0:
            below = np.clip((dr[1] + 0.35) / 1.35, 0, 1); fall *= 0.04 + 0.96 * below ** down
        out = out + np.array(col) * ndl * fall * (door_gain if i == 0 else 1.0)
    return out


def zone_lum(D, opened, door_gain, exposure, zone):
    """Screen-linear luminance (up to the art's constant) of a zone: the vertex colours (sRGB multipliers)
    interpolated as the mesh does, then raised back to linear."""
    h, u, n = (np.array(D[k], float) for k in ("h", "u", "n"))
    th = opened * np.pi / 2
    dirv = -u * np.cos(th) - n * np.sin(th); nroom = -n * np.cos(th) + u * np.sin(th)
    room = nroom[2] < 0
    base = h if room else h - nroom * 0.044
    nrm = nroom if room else -nroom
    def vc(col, row):
        p = base + dirv * 0.914 * col + np.array([0, 0.01 + row * 2.134, 0])
        lit = PAINT * light(p, nrm, D["L"], door_gain) * exposure
        return srgb(lit) / srgb(PAINT)
    V = np.array([[vc(c, r) for r in ROWS] for c in (0, 1)])  # 2 x rows x 3
    # hinge column is column 0 (the leaf runs from the hinge along dir)
    if zone == "head":
        cs, rs = np.linspace(0.0, 0.08, 3), np.linspace(0.78, 0.96, 5)
    elif zone == "low":
        cs, rs = np.linspace(0.92, 1.0, 3), np.linspace(0.04, 0.22, 5)
    else:
        cs, rs = np.linspace(0, 1, 9), np.linspace(0, 1, 21)
    vals = []
    for c in cs:
        for r in rs:
            row = np.array([np.interp(r, ROWS, V[k][:, ch]) for k in (0, 1) for ch in range(3)]).reshape(2, 3)
            v = row[0] * (1 - c) + row[1] * c
            vals.append((lin(v * srgb(PAINT)) * W).sum())
    return float(np.mean(vals))


if __name__ == "__main__":
    for nm, D in LEAVES.items():
        e = D["e"]
        for st, op in (("open", 1.0), ("shut", 0.0)):
            print(nm, st, {z: round(zone_lum(D, op, 1.0, e, z), 5) for z in ("head", "low", "all")})
