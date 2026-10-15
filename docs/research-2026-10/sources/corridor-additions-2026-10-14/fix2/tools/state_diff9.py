"""Round 9 (add7 fix round 2; copied from fix1/tools/state_diff8.py): where round 9 differs from round 8 (the build the
round-2 reviews saw, add7/shots/raw8/add) and from round 6 (add7/shots/raw8/r6) in each state (render.sh, -clean frames).
Differing pixels (> 3 levels) are grouped into blobs with their world box, so every change can be
matched to a fix. usage: state_diff8.py <720|phone> -> add7/shots/state-diff-<shape>.json"""
import json, os, sys
import numpy as np
from PIL import Image
from scipy import ndimage
R = "scratchpad/real-slice/add7/shots"
shape = sys.argv[1] if len(sys.argv) > 1 else "720"
REF = {"round8": os.path.join(R, "raw8", "add"), "round6": os.path.join(R, "raw8", "r6")}
NEW = os.path.join(R, "raw9", "add")
out = {}
for route in "AB":
    shots = {s["slug"]: s for s in json.load(open(os.path.join(NEW, f"{route}-{shape}", "_run.json")))["shots"]}
    for slug, sh in shots.items():
        b = np.asarray(Image.open(os.path.join(NEW, f"{route}-{shape}", slug + "-clean.png")).convert("RGB")).astype(int)
        H, W = b.shape[:2]
        cx, cy = (float(v) for v in sh["camera"].strip("()").split(","))
        s = float(sh["zoom"]) * W / 960.0
        entry = {"engineer_x": sh["engineer_x"], "wolf_x": sh["wolf_x"], "crank_frame": sh.get("crank_frame")}
        for name, base in REF.items():
            p = os.path.join(base, f"{route}-{shape}", slug + "-clean.png")
            if not os.path.exists(p):
                continue
            a = np.asarray(Image.open(p).convert("RGB")).astype(int)
            d = np.abs(a - b).max(-1)
            lab, n = ndimage.label(ndimage.binary_dilation(d > 3, iterations=3))
            blobs = []
            for i, sl in enumerate(ndimage.find_objects(lab)):
                m = (lab[sl] == i + 1) & (d[sl] > 3)
                if m.sum() < 4:
                    continue
                wx0 = (sl[1].start - W / 2) / s + cx; wx1 = (sl[1].stop - W / 2) / s + cx
                wy0 = (sl[0].start - H / 2) / s + cy; wy1 = (sl[0].stop - H / 2) / s + cy
                blobs.append({"screen_xywh": [sl[1].start, sl[0].start, sl[1].stop - sl[1].start, sl[0].stop - sl[0].start], "world_box": [round(wx0, 1), round(wy0, 1), round(wx1, 1), round(wy1, 1)], "px": int(m.sum()), "max": int(d[sl][m].max())})
            entry["vs_" + name] = {"pixels_over_3": int((d > 3).sum()), "blobs": sorted(blobs, key=lambda x: -x["px"])}
        out[slug] = entry
        r7 = entry.get("vs_round8", {})
        print(slug, "vs r8", r7.get("pixels_over_3"), [(bb["world_box"], bb["px"]) for bb in r7.get("blobs", [])[:7]])
json.dump(out, open(os.path.join(R, f"state-diff-{shape}.json"), "w"), indent=1)
