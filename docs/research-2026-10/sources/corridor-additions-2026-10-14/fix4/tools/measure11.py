"""Round 11 measurements of the blast frame's jamb plates in game (render.sh, clean frames, route A at
1280x720 and in phone shape), round 10 (raw10/add) against round 11 (raw11/add):
  - each jamb plate's on-screen width at 2 m (from the design geometry and the frame's camera),
  - its mean luma and the luma of the concrete beside it,
  - every bolt the design placed (add7/fix4/door/design/spec.json): the head's luma (3x3 px at its
    centre at 720p) against the plate round it (a ring 4-7 px out), and how many bolts stand out by at
    least 6 levels; round 10's bolts are measured at round 10's own design positions (one row of M24
    heads on the far plate, one head on the near head plate), so the counts compare like for like.
Writes add7/shots/measure11.json."""
import json
import os
import sys

sys.dont_write_bytecode = True
import numpy as np
from PIL import Image

R = "scratchpad/real-slice"
S = os.path.join(R, "add7", "shots")
sys.path.insert(0, os.path.join(R, "add7", "fix4", "door", "tools"))
import jamb11 as j  # noqa: E402
from jamb11 import p2  # noqa: E402

SPEC = json.load(open(os.path.join(R, "add7", "fix4", "door", "design", "spec.json")))
RUNS = {"round10": os.path.join(S, "raw10", "add"), "round11": os.path.join(S, "raw11", "add")}
LUM = np.array([0.2126, 0.7152, 0.0722])


def r10_bolts():
    """Round 7's bolt centres (unchanged to round 10): the far plate's one row and the near head bolt."""
    far = []
    for h in np.arange(0.15, j.d7.BF_TOP - 0.05, j.d7.BOLT_PITCH):
        if h < j.d7.H_OPEN - 0.05:
            far.append(p2.scr(p2.pt(j.d7.BF_A1 - 0.07, float(h), j.d7.BF_T - 0.012)))
    return far, []


def to_screen(wx, wy, shot, W, H):
    cx, cy = (float(v) for v in shot["camera"].strip("()").split(","))
    s = float(shot["zoom"]) * W / 960.0
    return (wx - cx) * s + W / 2, (wy - cy) * s + H / 2, s


def luma(img):
    return (img * LUM).sum(-1)


def bolt_stats(L, pts, shot, W, H):
    vals = []
    for wx, wy in pts:
        x, y, s = to_screen(wx, wy, shot, W, H)
        xi, yi = int(round(x)), int(round(y))
        if not (8 <= xi < W - 8 and 8 <= yi < H - 8):
            continue
        k = max(1, int(round(s * 0.6)))
        head = L[yi - k:yi + k + 1, xi - k:xi + k + 1].mean()
        yy, xx = np.mgrid[-int(4 * s):int(4 * s) + 1, -int(4 * s):int(4 * s) + 1]
        rr = np.hypot(yy, xx)
        ring = (rr >= 2.2 * s) & (rr <= 3.9 * s)
        patch = L[yi + yy[ring], xi + xx[ring]]
        vals.append(round(float(head - np.median(patch)), 1))
    return {"n": len(vals), "contrast": vals, "standing_out_6": int(sum(abs(v) >= 6 for v in vals)), "mean_abs_contrast": round(float(np.mean(np.abs(vals))), 1) if vals else None}


def region_luma(L, quad, shot, W, H):
    from PIL import ImageDraw
    m = Image.new("L", (W, H), 0)
    ImageDraw.Draw(m).polygon([to_screen(x, y, shot, W, H)[:2] for x, y in quad], fill=255)
    m = np.asarray(m) > 128
    return round(float(L[m].mean()), 1) if m.any() else None, int(m.sum())


def main():
    out = {"note": "luma 0-255 sRGB; bolt contrast = head minus the plate ring round it", "states": {}}
    far11 = [(c[2], c[3]) for c in SPEC["far"]["bolt_centres_a_h_worldxy"]]
    near11 = [(c[2], c[3]) for c in SPEC["near"]["bolt_centres_t_h_worldxy"]]
    far10, near10 = r10_bolts()
    for shape in ("720", "phone"):
        for slug in ("s1-door-end-rest", "s5-door-open", "s6-walk-through"):
            for tag, base in RUNS.items():
                d = os.path.join(base, f"A-{shape}")
                shot = {s["slug"]: s for s in json.load(open(os.path.join(d, "_run.json")))["shots"]}[slug]
                img = np.asarray(Image.open(os.path.join(d, slug + "-clean.png")).convert("RGB")).astype(float)
                H, W = img.shape[:2]
                L = luma(img)
                fa1 = j.FAR_A1 if tag == "round11" else j.d7.BF_A1
                fx0 = to_screen(*p2.scr(p2.pt(fa1, 2.0, j.BF_T)), shot, W, H)
                fx1 = to_screen(*p2.scr(p2.pt(j.A_F, 2.0, j.BF_T)), shot, W, H)
                nt1 = j.NEAR_T1 if tag == "round11" else 0.065
                nx0 = to_screen(*p2.scr(p2.pt(j.NEAR_A, 2.0, 0.0)), shot, W, H)
                nx1 = to_screen(*p2.scr(p2.pt(j.NEAR_A, 2.0, nt1)), shot, W, H)
                far_quad = [p2.scr(p2.pt(a, h, j.BF_T)) for a, h in ((j.A_F + 0.13, 0.4), (fa1, 0.4), (fa1, 2.9), (j.A_F + 0.13, 2.9))]
                conc_quad = [p2.scr(p2.pt(a, h, 0.0)) for a, h in ((j.A_BACK - 0.02, 0.4), (j.A_BACK - 0.17, 0.4), (j.A_BACK - 0.17, 2.9), (j.A_BACK - 0.02, 2.9))]
                near_quad = [p2.scr(p2.pt(j.NEAR_A, h, t)) for t, h in ((0.01, 0.6), (nt1 - 0.01, 0.6), (nt1 - 0.01, 3.6), (0.01, 3.6))]
                nconc_quad = [p2.scr(p2.pt(j.A_E, h, t)) for t, h in ((0.36, 0.6), (0.46, 0.6), (0.46, 1.3), (0.36, 1.3))]
                row = {"far_plate_screen_width_px_at_2m": round(fx1[0] - fx0[0], 1), "near_plate_screen_width_px_at_2m": round(nx1[0] - nx0[0], 1),
                       "far_plate_luma": region_luma(L, far_quad, shot, W, H)[0], "far_corner_concrete_luma": region_luma(L, conc_quad, shot, W, H)[0],
                       "near_plate_luma": region_luma(L, near_quad, shot, W, H)[0], "near_end_face_concrete_luma": region_luma(L, nconc_quad, shot, W, H)[0],
                       "far_bolts": bolt_stats(L, far11 if tag == "round11" else far10, shot, W, H),
                       "near_bolts": bolt_stats(L, near11, shot, W, H) if tag == "round11" else {"n": 0, "note": "round 10 had no bolts on the end face (a 65 mm arris angle)"}}
                out["states"].setdefault(f"{shape}/{slug}", {})[tag] = row
    json.dump(out, open(os.path.join(S, "measure11.json"), "w"), indent=1)
    for k, v in out["states"].items():
        for tag, r in v.items():
            print(k, tag, {kk: (vv if not isinstance(vv, dict) else {x: vv.get(x) for x in ("n", "standing_out_6", "mean_abs_contrast")}) for kk, vv in r.items()})


if __name__ == "__main__":
    main()
