"""Construction design of the corridor far-plate patch (the back wall and floor of the door end,
and the machinery room seen past the portal). Writes design/far-patch/.

Patch = far-plate source x 1112..1920, y 0..808 (808 x 808 px, 2 source px per world px).
Rows below 808 stay the original plate (the near floor), except the old lamp streak under the
removed lamp, which is inpainted in place by tools/far_floor.py at cleanup.
"""
from __future__ import annotations

import os
import sys

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
from common import (Canvas, Fixture, Part, draw_mask, rect, light, project, floor_y, depth_scale,
                    to_srgb_u8, from_srgb_u8, save_mask, write_json, PX_PER_M, VPX, HORIZON, FLOOR_Y)
import common

# --- CONFIG -----------------------------------------------------------------------------------
# ROOT is the design/ folder of the working folder the piece was built in (game-main/, an export of
# main at 76d3a50, sits beside it). It was a temporary session folder; point WOLF_DOOR_END_WORK at
# your own copy to run this tool again. Outputs are written under ROOT.
ROOT = os.path.join(os.environ.get("WOLF_DOOR_END_WORK", os.path.abspath("door-end-work")), "design")
# ------------------------------------------------------------------------------------------------
GAME = os.path.abspath(os.path.join(ROOT, "..", "game-main", "apps", "game"))
OUT = os.path.join(ROOT, "far-patch")
SRC_X0 = 1112
CANVAS = Canvas("far", x0=SRC_X0 / 2 + common.FAR_SHIFT, y0=78.5, ppw=2.0, w=808, h=808)
KEEP_ROWS = 192  # source rows above this stay the original ceiling pipes

D_CORR = 2.4  # corridor back wall, metres behind the walkway (floor line y 423.3)
D_MACH = 8.0  # machinery room back wall (floor line y 391.0)

common.AMBIENT = np.array([0.020, 0.036, 0.047])

F_CORR = Fixture("corridor vapour-tight luminaire (1.28 m, chain-hung 0.5 m off the wall)", (615.0, 190.5), 1.9, (0.72, 0.93, 1.0), 3.2, 1.3, 0.8)
F_MA = Fixture("machinery high-bay A (behind the portal header)", (790.0, 203.3), 4.0, (0.93, 0.96, 1.0), 4.0, 1.8, 2.0)
F_MB = Fixture("machinery high-bay B (visible, right of the portal)", (905.0, 201.2), 6.0, (0.93, 0.96, 1.0), 4.4, 1.8, 2.0)
CORR = (F_CORR,)
MACH = (F_MA, F_MB)


def wx(X_screen_at_depth: float, d: float) -> float:
    return X_screen_at_depth


def front_rect_at(d, x0, x1, h0, h1):
    """A rectangle on a front-facing plane at depth d, given screen x at that depth and heights (m)."""
    s = depth_scale(d)
    fy = floor_y(d)
    return rect(x0, fy - h1 * PX_PER_M * s, x1, fy - h0 * PX_PER_M * s)


def parts() -> list[Part]:
    P: list[Part] = []
    s_c = depth_scale(D_CORR)
    fy_c = floor_y(D_CORR)  # 423.3
    s_m = depth_scale(D_MACH)
    fy_m = floor_y(D_MACH)  # 391.0
    top = 174.5  # first designed row (source 192)

    # ---------------- machinery room (beyond the portal), drawn first (furthest back)
    P.append(Part("mach_wall", [rect(725, top, 980, fy_m)], (0.21, 0.215, 0.23), {"kind": "front", "d": D_MACH}, MACH,
                  dims="back wall of the machinery room, 8 m behind the walkway; floor line y 391.0",
                  note="cast concrete plant-room wall (hardened), form-panel joints every 1.2 m"))
    for i, x in enumerate(np.arange(737.0, 980.0, 1.2 * PX_PER_M * s_m)):
        P.append(Part(f"mach_wall_lap{i}", [rect(x, top, x + 1.0, fy_m)], (0.12, 0.16, 0.18), {"kind": "front", "d": D_MACH}, MACH,
                      dims="cladding lap 25 mm", note="sheet lap"))
    P.append(Part("mach_floor", [rect(725, fy_m, 980, fy_c + 0.01)], (0.16, 0.21, 0.23), {"kind": "floor"}, MACH,
                  dims="same slab as the corridor, 8 m deep here", note="sealed concrete, damp near the pump"))
    # roof truss bottom chord, just below the view top
    P.append(Part("mach_truss", [rect(725, top, 980, top + 3.0)], (0.18, 0.22, 0.25), {"kind": "front", "d": 5.0}, MACH,
                  dims="roof truss bottom chord, 0.15 m", note="carries the high-bays"))
    # catwalk along the back wall at 3.0 m (deck 7.2..8 m deep)
    d_cf = 7.2
    s_cf = depth_scale(d_cf)
    deck_front_y = floor_y(d_cf) - 3.0 * PX_PER_M * s_cf
    deck_back_y = fy_m - 3.0 * PX_PER_M * s_m
    P.append(Part("catwalk_deck", [rect(725, deck_back_y, 980, deck_front_y + 0.12 * PX_PER_M * s_cf)], (0.17, 0.21, 0.23), {"kind": "top", "h": 3.0}, MACH,
                  dims="grating deck 0.8 m wide at 3.0 m, 0.12 m toe board", note="service catwalk to the tank top"))
    rail_top = deck_front_y - 1.07 * PX_PER_M * s_cf
    rail_mid = deck_front_y - 0.53 * PX_PER_M * s_cf
    for name, yy, t in (("catwalk_rail_top", rail_top, 1.6), ("catwalk_rail_mid", rail_mid, 1.3)):
        P.append(Part(name, [rect(725, yy - t / 2, 980, yy + t / 2)], (0.20, 0.215, 0.255), {"kind": "front", "d": d_cf}, MACH,
                      dims="42 mm handrail" if "top" in name else "mid rail", note="36118 gunship-grey handrail (yellow is kept for the door's caught-between marking)"))
    for i, x in enumerate(np.arange(742.0, 980.0, 1.5 * PX_PER_M * s_cf)):
        P.append(Part(f"catwalk_post{i}", [rect(x - 0.8, rail_top, x + 0.8, deck_front_y)], (0.20, 0.215, 0.255), {"kind": "front", "d": d_cf}, MACH,
                      dims="post every 1.5 m", note="handrail post"))
    for i, x in enumerate((792.0, 952.0)):
        P.append(Part(f"catwalk_column{i}", [rect(x - 2.0, deck_front_y, x + 2.0, floor_y(d_cf))], (0.17, 0.21, 0.24), {"kind": "front", "d": d_cf}, MACH,
                      dims="100 mm square column on a base plate", note="carries the catwalk to the floor"))
        P.append(Part(f"catwalk_baseplate{i}", [rect(x - 3.5, floor_y(d_cf) - 1.0, x + 3.5, floor_y(d_cf) + 0.6)], (0.24, 0.28, 0.30), {"kind": "front", "d": d_cf}, MACH,
                      dims="base plate with two anchors", note="anchored to the slab"))
    # high-bay B (visible) with its pendant rod; A is hidden behind the portal header
    for f, tag in ((F_MB, "B"), (F_MA, "A")):
        sx, sy = f.screen
        s_f = depth_scale(f.d)
        r = 0.22 * PX_PER_M * s_f
        P.append(Part(f"highbay_{tag}_rod", [rect(sx - 0.5, top, sx + 0.5, sy - 2.0)], (0.22, 0.26, 0.28), {"kind": "front", "d": f.d}, MACH,
                      dims="pendant rod from the truss", note="hangs the luminaire"))
        P.append(Part(f"highbay_{tag}_body", [[(sx - r * 0.55, sy - 3.0), (sx + r * 0.55, sy - 3.0), (sx + r, sy), (sx - r, sy)]], (0.30, 0.33, 0.35), {"kind": "front", "d": f.d}, MACH,
                      dims="round LED high-bay, 0.44 m diameter", note="finned driver housing"))
        P.append(Part(f"highbay_{tag}_lens", [rect(sx - r, sy, sx + r, sy + 0.9)], (1, 1, 1), {"kind": "emit", "d": f.d}, (),
                      emit=(0.95, 0.97, 1.0), dims="lens", note="the light source"))
    # pump skid (seen through the doorway), 3 m behind the walkway
    d_p = 3.0
    s_p = depth_scale(d_p)
    fy_p = floor_y(d_p)
    m = PX_PER_M * s_p
    P.append(Part("pump_pad", [rect(752, fy_p - 0.1 * m, 812, fy_p)], (0.26, 0.29, 0.30), {"kind": "front", "d": d_p}, MACH,
                  dims="housekeeping pad 1.6 x 0.1 m", note="concrete pad the skid is grouted to"))
    P.append(Part("pump_base", [rect(754, fy_p - 0.17 * m, 810, fy_p - 0.1 * m)], (0.20, 0.25, 0.28), {"kind": "front", "d": d_p}, MACH,
                  dims="fabricated baseplate", note="carries motor and pump in line"))
    mc = fy_p - 0.45 * m
    mr = 0.22 * m
    P.append(Part("pump_motor", [rect(758, mc - mr, 784, mc + mr)], (0.20, 0.215, 0.255), {"kind": "cyl", "axis": "h", "cy": mc, "r": mr, "d": d_p, "cx": 771}, MACH,
                  dims="TEFC motor, 0.44 m frame, 0.7 m long", note="drives the coolant pump"))
    P.append(Part("pump_motor_feet", [rect(760, mc + mr, 764, fy_p - 0.17 * m), rect(777, mc + mr, 781, fy_p - 0.17 * m)], (0.16, 0.22, 0.27), {"kind": "front", "d": d_p}, MACH,
                  dims="motor feet", note="bolted to the baseplate"))
    P.append(Part("pump_coupling_guard", [rect(784, mc - mr * 0.6, 790, mc + mr * 0.6)], (0.16, 0.165, 0.185), {"kind": "front", "d": d_p}, MACH,
                  dims="coupling guard", note="36081 grey guard over the shaft coupling"))
    P.append(Part("pump_volute", [("ellipse", 797.0, mc + 1.0, 7.0, 8.0)], (0.26, 0.30, 0.33), {"kind": "front", "d": d_p}, MACH,
                  dims="end-suction pump casing 0.4 m", note="the coolant pump"))
    pr = 0.075 * m
    disc_x = 799.0
    elbow_y = fy_p - 2.4 * m
    P.append(Part("pump_discharge_riser", [rect(disc_x - pr, elbow_y, disc_x + pr, mc - 6.0)], (0.24, 0.29, 0.32), {"kind": "cyl", "cx": disc_x, "r": pr, "d": d_p}, MACH,
                  dims="DN150 discharge riser to 2.4 m", note="up and over to the tank"))
    P.append(Part("pump_discharge_run", [rect(disc_x - pr, elbow_y - pr, 900, elbow_y + pr)], (0.24, 0.29, 0.32), {"kind": "cyl", "axis": "h", "cy": elbow_y, "r": pr, "d": d_p}, MACH,
                  dims="DN150 run to the tank nozzle", note="enters the tank shell"))
    for i, fx in enumerate((disc_x - pr - 0.6, disc_x + pr - 0.6)):
        pass
    P.append(Part("pump_flanges", [rect(disc_x - pr - 1.2, mc - 7.5, disc_x + pr + 1.2, mc - 6.0), rect(842 - 1, elbow_y - pr - 1.2, 843.5, elbow_y + pr + 1.2)], (0.30, 0.34, 0.36), {"kind": "front", "d": d_p}, MACH,
                  dims="bolted flanges", note="pipe joints"))
    P.append(Part("pump_pipe_hanger", [rect(860.5, top + 3.0, 861.5, elbow_y - pr)], (0.20, 0.24, 0.26), {"kind": "front", "d": d_p}, MACH,
                  dims="threaded-rod hanger", note="carries the run from the truss"))
    # vertical coolant tank behind the safe point, 4 m back, on a plinth
    d_t = 4.0
    s_t = depth_scale(d_t)
    fy_t = floor_y(d_t)
    tm = PX_PER_M * s_t
    tcx = 893.0
    tr = 0.7 * tm
    ell = 0.7 * (FLOOR_Y - HORIZON) * (depth_scale(d_t - 0.7) - depth_scale(d_t + 0.7)) / 2.0  # floor ellipse half-height
    P.append(Part("tank_plinth", [rect(tcx - tr - 3, fy_t - 0.2 * tm, tcx + tr + 3, fy_t + ell)], (0.26, 0.29, 0.30), {"kind": "front", "d": d_t}, MACH,
                  dims="concrete plinth 0.2 m", note="tank base, four anchor chairs"))
    shell_top = fy_t - 5.0 * tm
    P.append(Part("tank_shell", [rect(tcx - tr, shell_top, tcx + tr, fy_t - 0.2 * tm), ("ellipse", tcx, fy_t - 0.2 * tm, tr, ell)], (0.25, 0.255, 0.27), {"kind": "cyl", "cx": tcx, "r": tr, "d": d_t}, MACH,
                  dims="1.4 m diameter x 5 m vertical expansion tank", note="carbon steel, 36231 grey"))
    P.append(Part("tank_head", [("ellipse", tcx, shell_top, tr, 0.35 * tm)], (0.28, 0.285, 0.30), {"kind": "top", "h": 5.2}, MACH,
                  dims="dished head", note="top of the tank"))
    for i, hh in enumerate((1.2, 3.8)):
        yy = fy_t - hh * tm
        P.append(Part(f"tank_seam{i}", [rect(tcx - tr, yy - 0.5, tcx + tr, yy + 0.5)], (0.20, 0.26, 0.29), {"kind": "cyl", "cx": tcx, "r": tr, "d": d_t}, MACH,
                      dims="shell weld seam", note="course joint"))

    # ---------------- corridor back wall (left of the portal)
    P.append(Part("corr_wall", [rect(570, top, 731, fy_c)], (0.30, 0.42, 0.47), {"kind": "front", "d": D_CORR}, CORR,
                  dims="corridor back wall, 2.4 m behind the walkway; floor line y 423.3", note="painted precast concrete panels, as the rest of the corridor"))
    dado_top = fy_c - 1.35 * PX_PER_M * s_c  # the original plate's dado line at source row 585
    P.append(Part("corr_dado", [rect(570, dado_top, 731, fy_c)], (0.20, 0.30, 0.35), {"kind": "front", "d": D_CORR}, CORR,
                  dims="dado band 1.35 m, darker paint", note="scuffed by trolleys and boots"))
    P.append(Part("corr_dado_line", [rect(570, dado_top - 0.6, 731, dado_top + 0.6)], (0.40, 0.52, 0.56), {"kind": "front", "d": D_CORR}, CORR,
                  dims="dado edge", note="paint break"))
    P.append(Part("corr_panel_joint", [rect(668.0, top, 668.8, fy_c)], (0.12, 0.18, 0.21), {"kind": "front", "d": D_CORR}, CORR,
                  dims="precast panel joint (2.4 m panels)", note="sealant joint"))
    # three service pipes at the original plate's rows 326/345/365, ending out of sight behind the portal
    for i, (cy, r) in enumerate(((241.5, 3.0), (251.0, 3.0), (261.0, 3.2))):
        P.append(Part(f"corr_pipe{i}", [rect(570, cy - r, 740, cy + r)], (0.22, 0.31, 0.36), {"kind": "cyl", "axis": "h", "cy": cy, "r": r, "d": D_CORR - 0.2}, CORR,
                      dims="DN100 service pipe", note="runs the length of the corridor, through the bulkhead"))
    for i, x in enumerate((612.0, 672.0)):
        P.append(Part(f"corr_pipe_clamp{i}", [rect(x - 1.5, 236.0, x + 1.5, 266.5)], (0.30, 0.38, 0.42), {"kind": "front", "d": D_CORR - 0.25}, CORR,
                      dims="strut clamp every 3 m", note="holds the pipes to the wall"))
    # beacon mount (the beacon itself is the game's live lockdown beacon at far (632.6, 224.3))
    bx = 632.6 + common.FAR_SHIFT
    P.append(Part("beacon_conduit", [rect(bx - 0.6, top, bx + 0.6, 216.0)], (0.38, 0.44, 0.47), {"kind": "front", "d": D_CORR - 0.05}, CORR,
                  dims="20 mm conduit to the ceiling tray", note="feeds the lockdown beacon"))
    P.append(Part("beacon_backbox", [rect(bx - 4.0, 213.0, bx + 4.0, 216.5)], (0.26, 0.32, 0.35), {"kind": "front", "d": D_CORR - 0.05}, CORR,
                  dims="back box 0.2 m", note="the beacon's stub bracket bolts here"))
    # the seam column (hides the join with the untouched plate) with base plate and anchors
    col_x0, col_x1 = 1116 / 2 + common.FAR_SHIFT, 1144 / 2 + common.FAR_SHIFT
    P.append(Part("seam_column_web", [rect(col_x0 - 2.0, 78.5, col_x1 + 2.0, fy_c)], (0.10, 0.14, 0.16), {"kind": "front", "d": D_CORR + 0.1}, CORR,
                  dims="shadow side of the column", note="the column stands just off the wall"))
    P.append(Part("seam_column", [rect(col_x0, 78.5, col_x1, fy_c)], (0.26, 0.36, 0.41), {"kind": "front", "d": D_CORR - 0.25}, CORR,
                  dims="W360 steel column, 0.36 m flange face, floor to roof", note="structural grid line; carries the roof"))
    P.append(Part("seam_column_baseplate", [rect(col_x0 - 2.0, fy_c - 1.6, col_x1 + 2.0, fy_c + 1.0)], (0.30, 0.38, 0.42), {"kind": "front", "d": D_CORR - 0.3}, CORR,
                  dims="base plate 0.5 m, four M24 anchors", note="grouted to the slab"))
    # the corridor luminaire, chain-hung over the walkway
    lx, ly = F_CORR.screen
    s_l = depth_scale(F_CORR.d)
    half = 1.28 * PX_PER_M * s_l / 2
    P.append(Part("lum_chains", [rect(lx - half + 6, 174.5, lx - half + 7, ly - 2.0), rect(lx + half - 7, 174.5, lx + half - 6, ly - 2.0)], (0.30, 0.34, 0.36), {"kind": "front", "d": F_CORR.d}, CORR,
                  dims="two jack chains to the ceiling strut", note="hangs the fitting"))
    P.append(Part("lum_housing", [rect(lx - half, ly - 2.2, lx + half, ly + 0.6)], (0.55, 0.60, 0.62), {"kind": "front", "d": F_CORR.d}, CORR,
                  dims="vapour-tight LED, 1.28 x 0.14 m (51 x 5 px)", note="polycarbonate housing, gasketed"))
    P.append(Part("lum_lens", [rect(lx - half + 1, ly + 0.6, lx + half - 1, ly + 2.0)], (1, 1, 1), {"kind": "emit", "d": F_CORR.d}, (),
                  emit=(0.82, 0.97, 1.0), dims="diffuser", note="the corridor's light source at the door end"))
    return P


def base_far() -> np.ndarray:
    """The original far plate with the removed lamp's floor streak (source x 1560..1720) replaced by
    the plain floor 160 px to its right, feathered over 24 px at each side."""
    far = np.asarray(Image.open(os.path.join(GAME, "assets/rooms/corridor-far.png")).convert("RGB")).astype(np.float64)
    out = far.copy()
    x0, x1, shift, feather = 1560, 1720, 160, 24
    for x in range(x0 - feather, x1 + feather):
        w = 1.0
        if x < x0:
            w = (x - (x0 - feather)) / feather
        elif x >= x1:
            w = 1.0 - (x - x1 + 1) / feather
        out[640:, x] = far[640:, x] * (1 - w) + far[640:, x + shift] * w
    return out.astype(np.uint8)


def render(parts_list: list[Part]):
    W, H = CANVAS.w, CANVAS.h
    far = base_far()
    orig = far[0:H, SRC_X0:SRC_X0 + W].astype(np.float64)
    lin = from_srgb_u8(orig)
    cover = np.zeros((H, W))
    masks = {}
    # original floor for rows below the corridor floor line, light added later
    for p in parts_list:
        m = draw_mask(CANVAS, p.polys)
        masks[p.name] = m
        if p.surface["kind"] == "emit":
            col = np.broadcast_to(np.array(p.emit), (H, W, 3))
        else:
            L = light(CANVAS, p.surface, [f for f in p.lit_by])
            col = np.array(p.albedo) * L
        lin = lin * (1 - m[..., None]) + col * m[..., None]
        cover = np.maximum(cover, m)
    # keep the original ceiling rows
    keep = np.zeros((H, W))
    keep[:KEEP_ROWS] = 1.0
    keep = keep * (1 - masks["seam_column"]) * (1 - masks["seam_column_web"])
    lin = lin * (1 - keep[..., None]) + from_srgb_u8(orig) * keep[..., None]
    # floor: light the original floor rows (y >= corridor floor line) with the corridor luminaire
    # and add its damp sheen; the machinery floor already has its own shading
    floor_rows = np.zeros((H, W))
    fy_px = int(round((floor_y(D_CORR) - CANVAS.y0) * CANVAS.ppw))
    floor_rows[fy_px:] = 1.0
    floor_rows *= (1 - cover)
    Lf = light(CANVAS, {"kind": "floor"}, [F_CORR])
    X, _ = CANVAS.grid()
    # the plant-room light reaches the floor only past the bulkhead, fading in over 50 px (no hard edge)
    Lm = light(CANVAS, {"kind": "floor"}, [F_MA, F_MB]) * np.clip((X - 820.0) / 50.0, 0, 1)[..., None]
    base = from_srgb_u8(orig)
    lit_floor = base * (0.75 + 0.9 * Lf / (Lf.max() + 1e-6)) + 0.6 * Lm * np.array([0.16, 0.21, 0.23])
    lin = lin * (1 - floor_rows[..., None]) + lit_floor * floor_rows[..., None]
    masks["corr_floor_keep"] = floor_rows
    masks["ceiling_keep"] = keep
    return lin, masks


def main() -> None:
    os.makedirs(os.path.join(OUT, "masks"), exist_ok=True)
    ps = parts()
    lin, masks = render(ps)
    img = to_srgb_u8(lin)
    Image.fromarray(img, "RGB").save(os.path.join(OUT, "design.png"))
    for name, m in masks.items():
        save_mask(m, os.path.join(OUT, "masks", f"{name}.png"))
    spec = {
        "canvas": {"name": CANVAS.name, "source_rect_in_corridor_far": [SRC_X0, 0, CANVAS.w, CANVAS.h], "px_per_world": CANVAS.ppw,
                   "world_origin_at_clamp": [CANVAS.x0, CANVAS.y0], "keep_original_rows": KEEP_ROWS},
        "fixtures": [{"name": f.name, "screen": f.screen, "depth_m": f.d, "color": f.color} for f in (F_CORR, F_MA, F_MB)],
        "parts": [{"name": p.name, "albedo": p.albedo, "surface": p.surface, "lit_by": [f.name for f in p.lit_by], "dims": p.dims, "job": p.note} for p in ps],
    }
    write_json(os.path.join(OUT, "spec.json"), spec)
    # full plate preview with the patch in place
    far = Image.fromarray(base_far(), "RGB")
    far.save(os.path.join(OUT, "far-base-streak-removed.png"))
    far.paste(Image.fromarray(img, "RGB"), (SRC_X0, 0))
    far.save(os.path.join(OUT, "far-plate-with-design.png"))
    print("far patch design written", img.shape)


if __name__ == "__main__":
    main()
