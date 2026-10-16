"""Edit target and paint map for the relay drop paint job (codex/paint-relay8/refs/): the relay art
with the round-8 construction drawn flat, 2.5x (920 x 1020) at (52, 2) on a 1024 x 1024 flat dark
field; WHITE = the new parts (drop, union, clamps, brackets, open end, damp patch)."""
import json
import os
import numpy as np
from PIL import Image
HERE = os.path.dirname(os.path.abspath(__file__))
D = os.path.join(HERE, "..", "design")
J = os.path.abspath(os.path.join(HERE, "..", "..", "codex", "paint-relay8"))
K, AT = 2.5, (52, 2)
os.makedirs(os.path.join(J, "refs"), exist_ok=True)
flat = Image.open(os.path.join(D, "flat.png")).convert("RGBA")
bg = Image.new("RGBA", flat.size, (36, 38, 42, 255))
bg.alpha_composite(flat)
big = bg.convert("RGB").resize((int(flat.width * K), int(flat.height * K)), Image.Resampling.LANCZOS)
t = Image.new("RGB", (1024, 1024), (36, 38, 42))
t.paste(big, AT)
t.save(os.path.join(J, "refs", "1-edit-target-relay.png"))
m = np.zeros(flat.size[::-1], bool)
for n in ("drop", "union", "clamps", "brackets", "end", "damp"):
    m |= np.asarray(Image.open(os.path.join(D, "masks", f"{n}.png"))) > 0
mi = Image.fromarray((m * 255).astype(np.uint8)).resize(big.size, Image.Resampling.NEAREST)
amap = Image.new("L", (1024, 1024), 0)
amap.paste(mi, AT)
amap.convert("RGB").save(os.path.join(J, "refs", "2-areas-to-paint.png"))
json.dump({"scale": K, "at": AT, "art": list(flat.size)}, open(os.path.join(J, "panels.json"), "w"), indent=1)
print("ok", big.size)
