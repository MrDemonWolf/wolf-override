"""Imports round 6's construction stack (design/tools, read-only: no bytecode written there)."""
import sys
sys.dont_write_bytecode = True
T = "scratchpad/real-slice/design/tools"
if T not in sys.path:
    sys.path.insert(0, T)
import common  # noqa
import portal2 as p2  # noqa
import portal3 as p3  # noqa
import portal4 as p4  # noqa
import portal5 as p5  # noqa
import portal6 as p6  # noqa
