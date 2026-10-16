"""Builds the Codex edit target and area map for the relief-valve paint job (deterministic)."""
import json
import os

import numpy as np
from PIL import Image
from scipy import ndimage

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
GAME = "scratchpad/real-slice/game-slice/apps/game"
RELAY = os.path.join(GAME, "assets/props/corridor-coolant-relay.png")
JOB = os.path.join(ROOT, "codex", "paint-relief")
FIELD = np.array([36, 38, 42], float)  # #24262A, the neutral field of the earlier jobs
OFF = (80, 112)  # where the 864x800 crop sits in the 1024x1024 frame
CROP = (260, 40, 368, 140)
S = 8


def main():
    os.makedirs(os.path.join(JOB, "refs"), exist_ok=True)
    hi = np.load(os.path.join(ROOT, "design", "hires.npz"))
    rgb, m = hi["rgb"], hi["mask"]
    relay = Image.open(RELAY).convert("RGBA").crop(CROP)
    up = np.array(relay.resize((relay.width * S, relay.height * S), Image.LANCZOS)).astype(float)
    a = up[..., 3:4] / 255.0
    base = up[..., :3] * a + FIELD * (1 - a)
    base[m] = rgb[m]
    frame = np.tile(FIELD, (1024, 1024, 1))
    h, w = base.shape[:2]
    frame[OFF[1]:OFF[1] + h, OFF[0]:OFF[0] + w] = base
    Image.fromarray(np.clip(np.round(frame), 0, 255).astype(np.uint8), "RGB").save(os.path.join(JOB, "refs", "1-edit-target-relief-valve.png"))
    area = np.zeros((1024, 1024), bool)
    area[OFF[1]:OFF[1] + h, OFF[0]:OFF[0] + w] = ndimage.binary_dilation(m, iterations=4)
    Image.fromarray((area * 255).astype(np.uint8), "L").save(os.path.join(JOB, "refs", "2-areas-to-paint.png"))
    with open(os.path.join(JOB, "inputs.json"), "w") as f:
        json.dump({"crop_art": CROP, "scale": S, "offset_in_frame": OFF, "frame": [1024, 1024]}, f, indent=1)


if __name__ == "__main__":
    main()
