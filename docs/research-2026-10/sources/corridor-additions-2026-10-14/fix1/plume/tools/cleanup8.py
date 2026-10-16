"""Relay drop cleanup, round 8. Codex's paint (codex/paint-relay8/out/relay8-painted.png, kept untouched
with its C2PA chunk; a resampled copy is used) is taken only inside the design masks of the new parts.
Its overall value is pinned to round 7's own painted tailpipe (one gain from the horizontal tailpipe
run, which both images show), so the new galvanised drop matches the pipe it continues. Outside the
masks every pixel is round 7's relay art, exactly.
Writes plume/layer/corridor-coolant-relay.png and report8.json."""
import json
import os

import numpy as np
from PIL import Image
from scipy import ndimage

HERE = os.path.dirname(os.path.abspath(__file__))
D = os.path.join(HERE, "..", "design")
J = os.path.abspath(os.path.join(HERE, "..", "..", "codex", "paint-relay8"))
OUT = os.path.abspath(os.path.join(HERE, "..", "layer"))
RELAY = "scratchpad/real-slice/add7/plume/layer/corridor-coolant-relay.png"
LUM = np.array([0.2126, 0.7152, 0.0722])


def main():
    os.makedirs(OUT, exist_ok=True)
    pan = json.load(open(os.path.join(J, "panels.json")))
    K, (ax, ay) = pan["scale"], pan["at"]
    orig = np.asarray(Image.open(RELAY).convert("RGBA")).astype(float)
    H, W = orig.shape[:2]
    big = Image.open(os.path.join(J, "out", "relay8-painted.png")).convert("RGB").resize((1024, 1024), Image.Resampling.LANCZOS)
    pw, ph = int(W * K), int(H * K)
    c = np.asarray(big.crop((ax, ay, ax + pw, ay + ph)).resize((W, H), Image.Resampling.LANCZOS)).astype(float)
    m = {n: np.asarray(Image.open(os.path.join(D, "masks", f"{n}.png"))) > 0 for n in ("drop", "union", "clamps", "brackets", "end", "damp")}
    # value pin: round 7's horizontal tailpipe run (rows 66..76, x 330..346), opaque, in both images
    ref = np.zeros((H, W), bool)
    ref[66:77, 330:347] = True
    ref &= orig[..., 3] > 250
    gain = float(((orig[..., :3] * LUM).sum(-1)[ref]).mean() / max(((c * LUM).sum(-1)[ref]).mean(), 1e-6))
    gain = float(np.clip(gain, 0.6, 1.6))
    out = orig.copy()
    solid = m["drop"] | m["union"] | m["clamps"] | m["brackets"] | m["end"]
    col = np.clip(c * gain, 0, 255)
    # 1-px soft edge across the pipe's sides (the drawing's pipes are antialiased)
    a = ndimage.gaussian_filter(solid.astype(float), 0.45)
    a = np.where(solid, np.maximum(a, 0.85), a * 0.9)
    newa = np.maximum(out[..., 3] / 255.0, a)
    out[..., :3] = np.where(a[..., None] > 0, (col * a[..., None] + out[..., :3] * (out[..., 3:4] / 255.0) * (1 - a[..., None])) / np.maximum(newa[..., None], 1e-6), out[..., :3])
    out[..., 3] = newa * 255
    # the damp patch: Codex's darker wet concrete, at most 45 % over the floor, feathered
    dm = m["damp"] & (orig[..., 3] < 10)
    da = ndimage.gaussian_filter(m["damp"].astype(float), 1.0) * 0.45 * (orig[..., 3] < 10)
    dcol = np.clip(c * gain * 0.8, 0, 255)
    out[..., :3] = np.where(da[..., None] > 0.01, dcol, out[..., :3])
    out[..., 3] = np.where(da > 0.01, np.maximum(out[..., 3], da * 255), out[..., 3])
    res = Image.fromarray(out.round().clip(0, 255).astype(np.uint8), "RGBA")
    res.save(os.path.join(OUT, "corridor-coolant-relay.png"))
    r = np.asarray(res).astype(int)
    changed = np.abs(r - orig.round().astype(int)).max(-1) > 0
    near = ndimage.binary_dilation(solid | m["damp"], iterations=2)
    rep = {"gain_to_round7_tailpipe": round(gain, 3), "changed_px": int(changed.sum()), "changed_outside_masks_px": int((changed & ~near).sum()),
           "drop_mean_luma": round(float((r[..., :3] * LUM).sum(-1)[m["drop"]].mean()), 1),
           "tailpipe_mean_luma": round(float((orig[..., :3] * LUM).sum(-1)[ref].mean()), 1)}
    json.dump(rep, open(os.path.join(OUT, "report8.json"), "w"), indent=1)
    print(json.dumps(rep, indent=1))


if __name__ == "__main__":
    main()
