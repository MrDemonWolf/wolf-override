"""Fix round 4 (v5): builds the game-ready files from layers/v5 exactly as install4.py does from v4
(same pieces, same shelf packing, same regions) and copies them into game-slice:
corridor-mid.png (unchanged recipe), corridor-far.png (layers/v5: the new bay's finish and the
beacon's mount), corridor-seal-atlas.png (the column with the guide's return and closed seams).
Writes layers/v5/game/."""
from __future__ import annotations

import os

import install4

install4.L = os.path.join(install4.R, "layers", "v5")
install4.OUT = os.path.join(install4.L, "game")

if __name__ == "__main__":
    install4.main()
