"""Fix round 5 (v6): builds the game-ready files from layers/v6 exactly as install4.py does from v4
(same pieces, same shelf packing, same regions; placement.json is identical to v5's) and copies them
into game-slice: corridor-mid.png (unchanged recipe, md5-identical to v5's), corridor-far.png
(layers/v6: v5's plate with the tank's faint rim from high-bay B), corridor-seal-atlas.png (the
column with the lamp conduit's elbow, run, strap and corner into the camera's wall plate; the wall
piece without the old camera ghost). Writes layers/v6/game/."""
from __future__ import annotations

import os

import install4

install4.L = os.path.join(install4.R, "layers", "v6")
install4.OUT = os.path.join(install4.L, "game")

if __name__ == "__main__":
    install4.main()
