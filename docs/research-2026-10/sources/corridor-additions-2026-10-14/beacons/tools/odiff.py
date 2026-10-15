"""Diff two capture folders frame by frame; report changed-pixel clusters (threshold 8 on any channel)."""
import sys, os, json
import numpy as np
from PIL import Image
from scipy import ndimage
a_dir, b_dir = sys.argv[1], sys.argv[2]
out = {}
for f in sorted(os.listdir(a_dir)):
    if not f.endswith('.png') or not os.path.exists(os.path.join(b_dir, f)):
        continue
    a = np.asarray(Image.open(os.path.join(a_dir, f)).convert('RGB')).astype(int)
    b = np.asarray(Image.open(os.path.join(b_dir, f)).convert('RGB')).astype(int)
    m = np.abs(a - b).max(2) > 8
    lab, n = ndimage.label(ndimage.binary_dilation(m, iterations=3))
    cl = []
    for s in ndimage.find_objects(lab):
        px = int(m[s].sum())
        if px == 0: continue
        cl.append({"bbox_xywh": [s[1].start, s[0].start, s[1].stop - s[1].start, s[0].stop - s[0].start], "px": px})
    cl.sort(key=lambda c: -c["px"])
    out[f] = {"changed_px": int(m.sum()), "clusters": cl[:8], "n_clusters": len(cl)}
    print(f, int(m.sum()), [ (c["bbox_xywh"], c["px"]) for c in cl[:5]])
json.dump(out, open(sys.argv[3], 'w'), indent=1) if len(sys.argv) > 3 else None
