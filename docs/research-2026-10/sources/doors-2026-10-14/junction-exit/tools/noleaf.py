"""The open state without the leaf (scratch only): what lies behind the leaf everywhere it can be
(the pocket, the passage, the rear of the sill), for the 'beyond' layer. Usage: noleaf.py DESIGN_DIR"""
import sys
sys.path.insert(0, __file__.rsplit("/", 1)[0])
import design as d  # noqa: E402
import geom as g  # noqa: E402
D = sys.argv[1]
d.EXPOSURE = float(open(f"{D}/exposure.txt").read())
d.render_state(g.LEAD_OPEN, D, "noleaf", with_leaf=False)
print("noleaf done")
