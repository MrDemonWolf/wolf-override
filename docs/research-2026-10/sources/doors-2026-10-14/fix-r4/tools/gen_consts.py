"""Fix round 4 (M1): the fitted leaf lights as GDScript constants (records_room.gd, junction_room.gd).
usage: gen_consts.py GAINS_JSON  -> prints each leaf's LIGHTS array and FILL value"""
import json, os, sys
import numpy as np
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import fit as F

NAMES = {"records-exit": "EXIT_LEAF", "records-entry": "ENTRY_LEAF", "junction-entry": "ENTRY_LEAF"}
COMMENTS = ["the door light over the head (the design's: reach 1.4 m, down 2.0; true Lambert)",
            "the room's ceiling lamp",
            "the broad floor bounce (fill)",
            "the door light's pool on the wet deck in front of the doorway",
            "the lit threshold and passage deck seen through the doorway",
            "the cross-wall's own lit face beyond the hinge jamb"]


def v3(a):
    return "Vector3(%s)" % ", ".join("%.4f" % float(x) for x in a)


def main():
    gains = json.load(open(sys.argv[1]))
    for name, g in gains.items():
        cfg = F.config(name, np.log([max(g[k], 1e-12) for k in F.KNOBS]))
        print(f"# {name}")
        print(f"const {NAMES[name]}_FILL: float = {cfg['fill']:.4f}")
        print(f"const {NAMES[name]}_LIGHTS: Array = [")
        for (pos, col, reach, down, wrap, is_fill), cm in zip(cfg["lights"], COMMENTS):
            if max(col) < 1e-6:
                continue
            extra = ", true" if is_fill else ""
            print(f"\t[{v3(pos)}, {v3(col)}, {reach:.2f}, {down:.1f}, {wrap:.2f}{extra}],  # {cm}")
        print("]")


if __name__ == "__main__":
    main()
