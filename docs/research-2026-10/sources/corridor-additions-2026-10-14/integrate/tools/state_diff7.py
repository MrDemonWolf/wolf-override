"""Round 7 integration: where the additions differ from round 6 in each door-end state (render.sh,
-clean frames, same driver and container). Differing pixels are grouped into blobs; each blob's
world box (from the shot's camera and zoom; the far plate's beacons scroll with parallax, so their
world x is approximate) is printed so every change can be matched to an addition.
usage: state_diff7.py <shape 720|phone>  -> add7/shots/state-diff-<shape>.json"""
import json, os, sys
import numpy as np
from PIL import Image
from scipy import ndimage
R = "scratchpad/real-slice"
RAW = os.path.join(R, "add7", "shots", "raw7")
shape = sys.argv[1] if len(sys.argv) > 1 else "720"
out = {}
for route in "AB":
    for copy in ("r6", "add"):
        if not os.path.exists(os.path.join(RAW, copy, f"{route}-{shape}", "_run.json")):
            break
    else:
        shots = {s["slug"]: s for s in json.load(open(os.path.join(RAW, "add", f"{route}-{shape}", "_run.json")))["shots"]}
        for slug, sh in shots.items():
            a = np.asarray(Image.open(os.path.join(RAW, "r6", f"{route}-{shape}", slug + "-clean.png")).convert("RGB")).astype(int)
            b = np.asarray(Image.open(os.path.join(RAW, "add", f"{route}-{shape}", slug + "-clean.png")).convert("RGB")).astype(int)
            H, W = a.shape[:2]
            cx, cy = (float(v) for v in sh["camera"].strip("()").split(","))
            s = float(sh["zoom"]) * W / 960.0
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
            out[slug] = {"pixels_over_3": int((d > 3).sum()), "blobs": sorted(blobs, key=lambda x: -x["px"])}
            print(slug, (d > 3).sum(), [(bb["world_box"], bb["px"]) for bb in out[slug]["blobs"][:8]])
json.dump(out, open(os.path.join(R, "add7", "shots", f"state-diff-{shape}.json"), "w"), indent=1)
