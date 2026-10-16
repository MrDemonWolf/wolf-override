import json, os, sys
import numpy as np
from PIL import Image
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import rmodel as M
def bbox(piece, job, prefixes):
    spec = json.load(open(os.path.join(M.DESIGN, piece, "spec.json")))["canvas"]
    lay = json.load(open(os.path.join(M.TRACK, "..", "codex", job, "layout.json")))
    k = lay["target"][0] / lay["world_w"]
    D = os.path.join(M.DESIGN, piece, "masks")
    u = None
    for f in os.listdir(D):
        if any(f.startswith(p) for p in prefixes):
            m = np.asarray(Image.open(os.path.join(D, f))) > 128
            u = m if u is None else (u | m)
    ys, xs = np.nonzero(u)
    X = spec["x0"] + xs / spec["ppw"]; Y = spec["y0"] + ys / spec["ppw"]
    return [int((X.min() - lay["world_x0"]) * k), int((Y.min() - lay["world_y0"]) * k), int((X.max() - lay["world_x0"]) * k), int((Y.max() - lay["world_y0"]) * k)]
for piece in ("exit", "entry"):
    job = f"records-{piece}-fix"
    for pr in (["wall--face"], ["wall--pipe_plate"], ["wall--sign"], ["wall--cam"], ["wall--light", "wall--jb", "wall--hss"], ["wall--frame", "wall--hinge", "wall--stop", "wall--reveal", "wall--threshold"], ["front--col", "front--arris", "front--frame", "front--lamp"], ["front--stub"], ["beyond--"]):
        try:
            print(piece, pr, bbox(piece, job, pr))
        except Exception as e:
            print(piece, pr, None)
