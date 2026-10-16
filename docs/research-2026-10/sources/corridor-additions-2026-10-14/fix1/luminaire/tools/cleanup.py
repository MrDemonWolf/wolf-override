"""Luminaire cleanup, round 8. Codex's paint (codex/paint-lum8/out/lum8-painted.png, kept untouched with its
C2PA chunk; a resampled copy is used) is taken only inside the design masks:
  body, end caps, rods, canopies   design value x Codex's relative detail (high-pass, clamped)
  diffuser                         Codex's own milky glow, pinned to the design's mean value
  inpaint (old bar ends, rods)     the deterministic inpaint x Codex's relative concrete grain
Outside the masks every pixel of the far plate is round 6's, exactly. Writes luminaire/layer/
corridor-far.png (the whole plate) and report.json."""
import json
import os

import numpy as np
from PIL import Image
from scipy import ndimage

HERE = os.path.dirname(os.path.abspath(__file__))
sys_path = HERE
import sys
sys.path.insert(0, HERE)
import design as D  # noqa: E402

J = os.path.abspath(os.path.join(HERE, "..", "..", "codex", "paint-lum8"))
OUT = os.path.abspath(os.path.join(HERE, "..", "layer"))
LUM = np.array([0.2126, 0.7152, 0.0722])


def detail(img, m, sigma, lo, hi):
    y = np.maximum((img * LUM).sum(-1), 1e-3)
    w = m.astype(float)
    base = ndimage.gaussian_filter(y * w, sigma) / np.maximum(ndimage.gaussian_filter(w, sigma), 1e-6)
    return np.clip(np.where(m, y / np.maximum(base, 1e-3), 1.0), lo, hi)


def main():
    os.makedirs(OUT, exist_ok=True)
    pan = json.load(open(os.path.join(J, "panels.json")))
    K, (ax, ay) = pan["scale"], pan["at"]
    W, H = pan["crop"]
    big = Image.open(os.path.join(J, "out", "lum8-painted.png")).convert("RGB").resize((1024, 1024), Image.Resampling.LANCZOS)
    c = np.asarray(big.crop((ax, ay, ax + W * K, ay + H * K)).resize((W, H), Image.Resampling.LANCZOS)).astype(float)
    flat = np.asarray(Image.open(os.path.join(D.OUT, "flat.png")).convert("RGB")).astype(float)
    crop6 = np.asarray(Image.open(os.path.join(D.OUT, "crop-round6.png")).convert("RGB")).astype(float)
    m = {n: np.asarray(Image.open(os.path.join(D.OUT, "masks", f"{n}.png"))) > 0 for n in ("body", "end_caps", "diffuser", "hanger_rods", "canopies", "inpaint")}
    out = crop6.copy()
    hard = m["body"] | m["hanger_rods"] | m["canopies"]
    # the fitting was painted PAINT_SHIFT px to the right of where it now hangs: sample its paint there
    cs = np.roll(c, -D.PAINT_SHIFT, axis=1)
    dt = detail(cs, hard, 2.0, 0.8, 1.25)
    out[hard] = (flat * dt[..., None])[hard]
    d = m["diffuser"]
    gain = (flat[d] * LUM).sum(-1).mean() / max((cs[d] * LUM).sum(-1).mean(), 1e-3)
    out[d] = np.clip(cs[d] * gain, 0, 255)
    # the bar ends and rods taken back to the wall: the deterministic inpaint (its grain is the wall's
    # own), no paint (the painted image had the fitting where part of this wall now is)
    ip = m["inpaint"] & ~hard & ~d
    out[ip] = flat[ip]
    out = np.clip(out, 0, 255).round().astype(np.uint8)
    far = np.asarray(Image.open(D.FAR).convert("RGB")).copy()
    far[D.CY0:D.CY1, D.CX0:D.CX1] = out
    Image.fromarray(far).save(os.path.join(OUT, "corridor-far.png"))
    orig = np.asarray(Image.open(D.FAR).convert("RGB"))
    ch = np.abs(far.astype(int) - orig.astype(int)).max(-1) > 0
    ys, xs = np.nonzero(ch)
    rep = {"changed_px": int(ch.sum()), "changed_bbox_plate": [int(xs.min()), int(ys.min()), int(xs.max()) + 1, int(ys.max()) + 1], "diffuser_gain": round(float(gain), 3),
           "fitting_plate_x": [D.X0, D.X1], "old_bar_plate_x": [1232, 1327]}
    json.dump(rep, open(os.path.join(OUT, "report.json"), "w"), indent=1)
    Image.fromarray(np.concatenate([crop6.astype(np.uint8), out], 1)).resize((W * 2 * 5, H * 5), Image.Resampling.NEAREST).save(os.path.join(OUT, "check-5x.png"))
    print(json.dumps(rep))


if __name__ == "__main__":
    main()
