"""Target-frame bounding boxes of design parts (for the Codex prompts)."""
import os, sys
import numpy as np
from PIL import Image
sys.path.insert(0, os.path.dirname(__file__))
import jmodel as M
from codex_inputs import TX0, TY0, TX1, TY1, TW, TH
S = TW / (TX1 - TX0)
def bbox(layer, prefix):
    D = os.path.join(M.WORK, "design", "masks")
    u = None
    for f in os.listdir(D):
        if f.startswith(f"{layer}--{prefix}"):
            m = np.asarray(Image.open(os.path.join(D, f))) > 128
            u = m if u is None else (u | m)
    ys, xs = np.nonzero(u)
    X = M.CV.x0 + xs / M.CV.ppw; Y = M.CV.y0 + ys / M.CV.ppw
    return [int((X.min() - TX0) * S), int((Y.min() - TY0) * S), int((X.max() - TX0) * S), int((Y.max() - TY0) * S)]
if __name__ == "__main__":
    for arg in sys.argv[1:]:
        l, p = arg.split(":")
        print(arg, bbox(l, p))
