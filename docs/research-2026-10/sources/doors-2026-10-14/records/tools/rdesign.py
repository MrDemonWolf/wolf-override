"""Records Access doors (doors-r1, records track): construction design. Scratch only; no image tool
touches this step. Every part is drawn from measured numbers in rmodel.py, gets its own mask, a
named job and real dimensions, and is lit by named, visible fixtures.

Pieces (all in the game camera, rmodel.py):
  exit   the right end of the room: a 300 mm cast cross-wall turned 17 degrees across the walkway
         (XC = 880: the shut leaf crosses the walk line there) with a 3'0" x 7'0" steel secure-area
         door (ICD 705 TS v1.4 3E: 1-3/4 in steel, automatic non-hold closer inside, high security
         switch, FF-L-2890 lock; secondary door: no combination lock) that swings INTO the room on
         three 4-1/2 in hinges (SDI 129-24 spacing), driven open by a concealed low-energy operator in
         its header (ANSI/BHMA A156.19: 3 s or longer to 80 degrees). Layers:
           wall    behind the walk line (approach face, header, frame, far reveal, threshold, hinges,
                   door light, high security switch, conduit, floor stop), doorway alpha 0
           front   over the actors: the near column (approach strip, near jamb frame, end face with the
                   guarded status lamp, steel arris angles) and the 0.15 m stub running to the camera
           beyond  the service line passage behind the wall (painted into the far plate)
  entry  the left end, mirrored (XE = 70): the primary entrance from the corridor side, the same
         door type (its outside face carries the FF-L-2740 combination lock), with the vestibule
         behind it.
  leaf   the door leaf's faces, flat in the leaf's own plane (the game swings it as a mesh):
         room face, exit outside face, entry outside face, latch edge.
  container  a GSA Class 5 four-drawer legal security container (58-1/2 x 20-7/8 x 33-1/2 in, one
         FF-L-2740 lock on the top drawer controls all drawers): where the first copy is secured.
Writes design/<piece>/ (design-*.png flat-shaded renders, masks/<layer>--<part>.png, spec.json).
"""
from __future__ import annotations

import math
import os
import sys

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import rmodel as M  # noqa: E402
from rmodel import Part, Lamp, DoorEnd, Canvas, Plane, EY  # noqa: E402

XC = 880.0  # exit: the shut leaf's room face crosses the walk line here
XE = 70.0  # entry
CONTAINER_X = 797.0  # the security container's centre; worked from its right, clear of the exit leaf's swing
CONTAINER_FRONT_D = 0.12  # just behind the walk line, like the other stations: the actors pass in front
FAR_SHIFT_RIGHT = 12.444  # far-plate parallax at the camera's right clamp (camera x 604.444)
FAR_SHIFT_LEFT = -12.444  # and at its left clamp (camera x 355.556)
PASSAGE_D = 1.6  # the service line passage's back wall, behind the walk line
OUT = M.DESIGN


def lamps_for(side):
    if side > 0:
        door = DoorEnd(1, XC)
        f_door = Lamp("exit door light: vapour-tight LED 0.6 m on the cross-wall face over the door", door.pt(0.0, 2.80, -0.10), (0.86, 0.95, 1.0), 0.95, 1.4, 2.0)
        f_room = Lamp("Records ceiling lamp 1 (far plate, painted)", M.from_screen(588.4, 211.0, 4.3), (0.72, 0.93, 1.0), 0.9, 3.2, 1.5)
        f_pass = Lamp("service line passage light: vapour-tight LED on the passage back wall", M.from_screen(936.0, 300.0, PASSAGE_D - 0.12), (0.80, 0.92, 1.0), 1.25, 1.9, 1.5)
    else:
        door = DoorEnd(-1, XE)
        f_door = Lamp("entry door light: vapour-tight LED 0.6 m on the cross-wall face over the door", door.pt(0.0, 2.80, -0.10), (0.86, 0.95, 1.0), 0.95, 1.4, 2.0)
        f_room = Lamp("Records ceiling lamp 0 (far plate, painted)", M.from_screen(178.6, 211.0, 4.3), (0.72, 0.93, 1.0), 0.9, 3.2, 1.5)
        f_pass = Lamp("vestibule light: vapour-tight LED on the vestibule back wall", M.from_screen(18.0, 300.0, PASSAGE_D - 0.12), (0.80, 0.92, 1.0), 0.55, 1.4, 1.5)
    bounce = Lamp("floor bounce (wet floor in front, a fill)", np.array([door.O[0] - door.side * 2.0, 0.1, -3.0]), (0.55, 0.75, 0.85), 0.10, 4.0)
    return door, [f_door, f_room, f_pass, bounce], f_door, f_pass


def wall_parts(door: DoorEnd, lamps):
    d = door
    P = []
    fp = d.face_plane(0.0)
    FF, T = d.FRAME_FACE, d.T_WALL
    head_top = d.H_OPEN + d.HEADER_H
    P.append(Part("wall", "reveal_far", [d.quad_side(d.A_F, 0.0, T, 0.0, d.H_OPEN)], M.STEEL, d.side_plane(d.A_F),
                  "far (hinge) jamb reveal: the frame's steel throat lining the 300 mm wall", "the wall's thickness, steel-lined at the opening"))
    P.append(Part("wall", "stop_far", [d.quad_side(d.A_F - 0.016, 0.044, 0.060, 0.0, d.H_OPEN)], M.GUNSHIP, d.side_plane(d.A_F - 0.016),
                  "frame stop 16 mm (5/8 in)", "the leaf closes against it; carries the acoustic seal"))
    P.append(Part("wall", "threshold", [d.quad_top(d.A_N, d.A_F, -0.04, T + 0.04, 0.006)], (0.30, 0.305, 0.32), d.top_plane(0.006),
                  "steel threshold 0.38 m x 0.92 m", "metal threshold; the door bottom seal lands on it (acoustic, ICD 705 ch. 9)"))
    P.append(Part("wall", "face_back", [d.quad_face(d.A_F + FF, d.A_BACK, 0.0, d.H_TOP)], M.CONCRETE, fp,
                  "cast reinforced-concrete cross-wall, 300 mm, from the hinge jamb to the room's back wall", "closes the Records room's end"))
    P.append(Part("wall", "face_head", [d.quad_face(d.A_N - FF, d.A_F + FF, head_top, d.H_TOP)], M.CONCRETE, fp,
                  "the wall over the door", "carries the door light and the switch box"))
    P.append(Part("wall", "pour_joint", [d.quad_face(d.A_N - FF, d.A_BACK, 3.60 - 0.012, 3.60 + 0.012)], M.CONCRETE_DK, fp,
                  "pour line between concrete lifts at 3.6 m", "construction joint", texture="seam"))
    P.append(Part("wall", "back_corner", [d.quad_face(d.A_BACK - 0.05, d.A_BACK, 0.0, d.H_TOP, -0.002)], M.CONCRETE_DK, d.face_plane(-0.002),
                  "internal corner with the room's back wall", "where the cross-wall meets the back wall"))
    P.append(Part("wall", "frame_far_jamb", [d.quad_face(d.A_F, d.A_F + FF, 0.0, d.H_OPEN, -0.012)], M.GUNSHIP, d.face_plane(-0.012),
                  "hollow-metal frame, 2 in face", "hinge jamb; three anchors per jamb grout it into the wall"))
    P.append(Part("wall", "frame_head", [d.quad_face(d.A_N - FF, d.A_F + FF, d.H_OPEN, head_top, -0.012)], M.GUNSHIP, d.face_plane(-0.012),
                  "header 120 mm with the concealed low-energy operator and closer", "opens the door on release (ANSI/BHMA A156.19) and closes it (non-hold closer inside, ICD 705 3E.3)"))
    P.append(Part("wall", "frame_head_seam", [d.quad_face(d.A_N - FF + 0.02, d.A_F + FF - 0.02, d.H_OPEN + 0.055, d.H_OPEN + 0.062, -0.013)], M.DARK, d.face_plane(-0.013),
                  "header access-panel joint", "the operator's removable cover", texture="seam"))
    for i, (h0, h1) in enumerate(d.HINGES):
        c0 = d.pt(d.A_F, h0, -0.012)
        c1 = d.pt(d.A_F, h1, -0.012)
        x0, y0 = M.scr(c0)
        x1, y1 = M.scr(c1)
        r = 0.009 * M.PX_PER_M
        P.append(Part("wall", f"hinge{i}", [[(x0 - r, y0), (x0 + r, y0), (x1 + r, y1), (x1 - r, y1)]], M.STEEL, Plane(c0, door.U, EY, -door.N),
                      "4-1/2 in heavy-weight hinge knuckle (SDI 129-24 location)", "carries the leaf; on the room side (in-swing), pins inside the secure area (ICD 705 3E.5)"))
    # door light, switch box and conduit on the face over the door
    P.append(Part("wall", "light_bracket", [d.quad_face(-0.04, 0.04, 2.76, 2.88, -0.02)], M.HOUSING, d.face_plane(-0.02), "fixing bracket", "holds the fitting off the wall"))
    P.append(Part("wall", "light_body", [d.quad_face(-0.30, 0.30, 2.76, 2.84, -0.10)], M.HOUSING, d.face_plane(-0.10),
                  "vapour-tight LED fitting 0.6 m", "lights the door, its threshold and the floor in front"))
    P.append(Part("wall", "light_diffuser", [d.quad_face(-0.28, 0.28, 2.745, 2.765, -0.11)], M.FITTING_LENS, d.face_plane(-0.11),
                  "opal diffuser (unlit paint; its light is in the surfaces)", "the fitting's lens", texture=None))
    jb_a0, jb_a1 = d.A_N + 0.05, d.A_N + 0.22
    P.append(Part("wall", "jb_box", [d.quad_face(jb_a0, jb_a1, 2.98, 3.16, -0.10)], M.GUNSHIP, d.face_plane(-0.10),
                  "junction box 170 x 180 mm, tamper switch inside", "terminates the light, switch and operator feeds"))
    P.append(Part("wall", "hss", [d.quad_face(d.A_N + 0.06, d.A_N + 0.22, head_top, head_top + 0.03, -0.035)], M.HOUSING, d.face_plane(-0.035),
                  "high security switch 160 x 30 mm on the header, latch side", "alarms before the door opens 1-3/4 in (ICD 705 TS 7: HSS)"))
    P.append(Part("wall", "hss_flex", [d.quad_face(d.A_N + 0.135, d.A_N + 0.150, head_top + 0.03, 2.98, -0.04)], M.DARK, d.face_plane(-0.04),
                  "armoured flex 12 mm", "switch to box"))
    P.append(Part("wall", "light_feed", [d.quad_face(jb_a1, -0.28, 3.035, 3.055, -0.05), d.quad_face(-0.30, -0.28, 2.84, 3.055, -0.05)], M.STEEL, d.face_plane(-0.05),
                  "20 mm rigid conduit", "box to the light"))
    P.append(Part("wall", "conduit_up", [d.quad_face(jb_a0 + 0.075, jb_a0 + 0.095, 3.16, d.H_TOP, -0.04)], M.STEEL, d.face_plane(-0.04),
                  "20 mm rigid conduit to the ceiling tray", "the feed from the facility's power and alarm panels"))
    P.append(Part("wall", "conduit_strap", [d.quad_face(jb_a0 + 0.06, jb_a0 + 0.11, 3.80, 3.84, -0.05)], M.DARK, d.face_plane(-0.05),
                  "one-hole strap within 0.9 m of the box", "holds the conduit"))
    # a fixed dome camera high on the face, watching the room (the facility is machine-run)
    cam_a, cam_h = 1.70, 4.10
    P.append(Part("wall", "cam_plate", [d.quad_face(cam_a - 0.08, cam_a + 0.08, cam_h + 0.02, cam_h + 0.20, -0.01)], M.HOUSING, d.face_plane(-0.01),
                  "wall plate 160 x 180 mm, two anchors", "fixes the camera arm"))
    P.append(Part("wall", "cam_arm", [d.poly([d.pt(cam_a - 0.02, cam_h + 0.13, -0.01), d.pt(cam_a - 0.02, cam_h + 0.13, -0.24), d.pt(cam_a + 0.02, cam_h + 0.09, -0.24), d.pt(cam_a + 0.02, cam_h + 0.09, -0.01)])], M.HOUSING, d.face_plane(-0.12),
                  "tubular arm 0.24 m", "holds the dome off the wall"))
    ccx, ccy = d.s(cam_a, cam_h + 0.03, -0.26)
    P.append(Part("wall", "cam_housing", [("ellipse", ccx, ccy - 0.6, 3.4, 1.6)], M.GUNSHIP, M.front_plane(d.pt(cam_a, 0, -0.26)[2]),
                  "vandal-resistant dome housing 170 mm", "watches the room; static art, no glow"))
    P.append(Part("wall", "cam_dome", [("ellipse", ccx, ccy + 0.9, 2.6, 1.6)], M.DARK, M.front_plane(d.pt(cam_a, 0, -0.26)[2]),
                  "smoked dome", "the lens cover"))
    P.append(Part("wall", "cam_conduit", [d.quad_face(cam_a - 0.010, cam_a + 0.010, cam_h + 0.20, d.H_TOP, -0.03)], M.STEEL, d.face_plane(-0.03),
                  "20 mm conduit to the ceiling tray", "the camera's feed"))
    # the floor stop where the open leaf's latch edge rests (90 degrees)
    tip = door.hinge + door.leaf_dir(math.pi / 2) * (door.LEAF_W - 0.06) + door.N * 0.03
    tx, ty = M.scr(tip)
    P.append(Part("wall", "floor_stop", [("ellipse", tx, ty - 0.5, 1.0, 0.7)], M.STEEL, d.top_plane(0.03),
                  "dome floor stop 35 mm, anchored", "holds the leaf open at 90 degrees"))
    return P


def front_parts(door: DoorEnd, x_limit):
    d = door
    P = []
    FF, T = d.FRAME_FACE, d.T_WALL
    A_E = d.A_END
    P.append(Part("front", "col_face", [d.quad_face(A_E, d.A_N - FF, 0.0, d.H_TOP)], M.CONCRETE, d.face_plane(0.0),
                  "the wall's end beside the near jamb: 0.16 m of approach face", "carries the latch-side frame"))
    P.append(Part("front", "col_end", [d.quad_side(A_E, 0.0, T, 0.0, d.H_TOP)], M.CONCRETE, d.side_plane(A_E),
                  "end face toward the camera, the wall's 300 mm", "the wall's end (cutaway); carries the status lamp"))
    P.append(Part("front", "arris_l", [d.quad_side(A_E - 0.004, 0.0, 0.05, 0.0, d.H_TOP)], M.STEEL, d.side_plane(A_E - 0.004),
                  "50 mm steel arris angle", "armours the room-side corner"))
    P.append(Part("front", "arris_r", [d.quad_side(A_E - 0.004, T - 0.05, T, 0.0, d.H_TOP)], M.STEEL, d.side_plane(A_E - 0.004),
                  "50 mm steel arris angle", "armours the far corner"))
    P.append(Part("front", "arris_face", [d.quad_face(A_E, A_E + 0.05, 0.0, d.H_TOP, -0.004)], M.STEEL, d.face_plane(-0.004),
                  "arris angle, face leg", "armours the corner"))
    P.append(Part("front", "frame_near_jamb", [d.quad_face(d.A_N - FF, d.A_N, 0.0, d.H_OPEN + d.HEADER_H, -0.012)], M.GUNSHIP, d.face_plane(-0.012),
                  "hollow-metal frame, 2 in face, latch jamb", "carries the strike and the electrified bolt"))
    tl = T / 2
    lamp_a = A_E - 0.10
    P.append(Part("front", "lamp_base", [d.quad_side(lamp_a, tl - 0.08, tl + 0.08, d.LAMP_H - 0.16, d.LAMP_H - 0.10)], M.HOUSING, d.side_plane(lamp_a),
                  "cast lamp body on a conduit box", "carries the globe"))
    P.append(Part("front", "lamp_cap", [d.quad_side(lamp_a, tl - 0.065, tl + 0.065, d.LAMP_H + 0.08, d.LAMP_H + 0.11)], M.HOUSING, d.side_plane(lamp_a),
                  "guard cap", "tops the wire guard"))
    for i, dt in enumerate((-0.05, 0.0, 0.05)):
        P.append(Part("front", f"lamp_guard{i}", [d.quad_side(A_E - 0.13, tl + dt - 0.006, tl + dt + 0.006, d.LAMP_H - 0.10, d.LAMP_H + 0.085)], M.STEEL, d.side_plane(A_E - 0.13),
                      "wire guard bar", "protects the globe"))
    P.append(Part("front", "lamp_conduit", [d.quad_side(A_E - 0.025, tl - 0.010, tl + 0.010, d.LAMP_H + 0.11, d.H_TOP)], M.STEEL, d.side_plane(A_E - 0.025),
                  "20 mm conduit up the end face", "feeds the status lamp from the ceiling tray"))
    for i, h in enumerate((d.LAMP_H + 0.50, d.LAMP_H + 1.35)):
        P.append(Part("front", f"lamp_strap{i}", [d.quad_side(A_E - 0.03, tl - 0.022, tl + 0.022, h, h + 0.035)], M.DARK, d.side_plane(A_E - 0.03),
                      "one-hole strap", "holds the conduit"))
    a_far = d.stub_far_a(x_limit)
    STUB = d.STUB_H
    P.append(Part("front", "stub_face", [d.quad_face(a_far, A_E, 0.0, STUB)], M.CONCRETE, d.face_plane(0.0),
                  "the cross-wall's 0.15 m stub, room-side face", "the wall's line carried to the camera (cutaway), a curb between the room and the passage"))
    P.append(Part("front", "stub_top", [d.quad_top(a_far, A_E, 0.0, T, STUB)], M.CONCRETE, d.top_plane(STUB),
                  "stub top, the wall's 300 mm", "the cut section, seen from above"))
    P.append(Part("front", "stub_angle_top", [d.quad_top(a_far, A_E, 0.0, 0.05, STUB + 0.003)], M.STEEL_WORN, d.top_plane(STUB + 0.003),
                  "50 mm steel edge angle, top leg", "armours the curb's room edge (carts)"))
    P.append(Part("front", "stub_angle_face", [d.quad_face(a_far, A_E, STUB - 0.05, STUB, -0.004)], M.STEEL, d.face_plane(-0.004),
                  "50 mm steel edge angle, face leg", "armours the curb's room edge"))
    return P, a_far


def lamp_screen(door):
    return M.scr(door.pt(door.A_END - 0.12, door.LAMP_H, door.T_WALL / 2))


def floor_coords(door, canvas, h=0.0):
    A, B = canvas.rays()
    tt = (h - A[1]) / np.where(np.abs(B[..., 1]) < 1e-9, -1e-9, B[..., 1])
    P = A + B * tt[..., None]
    rel = P - door.O
    return (rel * door.U).sum(-1), (rel * door.N).sum(-1), P


def wall_contact_shadow(door, canvas):
    a, t, _ = floor_coords(door, canvas)
    inside = (a >= door.A_F) & (a <= door.A_BACK) & (t <= 0)
    edge = np.clip(np.minimum(a - door.A_F, door.A_BACK - a) / 0.12, 0, 1)
    sh = np.where(inside, 0.55 * np.exp(-np.clip(-t, 0, 50) / 0.14) * edge, 0)
    return sh


def front_contact_shadow(door, canvas):
    a, t, _ = floor_coords(door, canvas)
    sh = np.zeros(a.shape)
    near = a <= door.A_END + 0.02
    sh = np.maximum(sh, np.where(near & (t < 0), 0.6 * np.exp(-np.clip(-t, 0, 50) / 0.10), 0))
    sh = np.maximum(sh, np.where(near & (t > door.T_WALL), 0.5 * np.exp(-np.clip(t - door.T_WALL, 0, 50) / 0.12), 0))
    face = (a >= door.A_END) & (a <= door.A_N) & (t < 0)
    sh = np.maximum(sh, np.where(face, 0.55 * np.exp(-np.clip(-t, 0, 50) / 0.12), 0))
    return sh


def beyond_parts(door: DoorEnd, lamps):
    """The space behind the wall, as seen at scroll 1.0: the service line passage (exit) or the
    vestibule (entry). Its back wall stands PASSAGE_D behind the walk line."""
    s = door.side
    P = []
    Dp = PASSAGE_D
    bw = M.front_plane(Dp)

    def beyond_wall(Pp):  # only what lies past the cross-wall's room face (hidden under the wall up to its far face, so the far plate's parallax never opens a gap)
        t = ((Pp - door.O) * door.N).sum(-1)
        return np.clip((t - 0.02) / 0.04, 0, 1)

    x0, x1 = (780.0, 1000.0) if s > 0 else (-40.0, 170.0)

    def rect_d(xa, xb, h0, h1, dd):
        a = M.project(xa, h0, dd)
        b = M.project(xb, h1, dd)
        return [(a[0], a[1]), (b[0], a[1]), (b[0], b[1]), (a[0], b[1])]

    def xw(X, dd):  # walkway x (px) of screen X at depth dd
        return M.VPX + (X - M.VPX) / M.depth_scale(dd)

    P.append(Part("beyond", "back_wall", [rect_d(xw(x0, Dp), xw(x1, Dp), 0.0, 8.5, Dp)], M.CONCRETE, bw,
                  "the passage's back wall, cast concrete", "the far side of the service line passage" if s > 0 else "the vestibule's back wall"))
    fl = Plane(np.array([0, 0.0, 0]), np.array([1.0, 0, 0]), np.array([0, 0, 1.0]), EY)
    fa = M.project(xw(x0, -3.0), 0.0, -3.0)
    fb = M.project(xw(x1, -3.0), 0.0, -3.0)
    fc = M.project(xw(x1, Dp), 0.0, Dp)
    fd = M.project(xw(x0, Dp), 0.0, Dp)
    P.append(Part("beyond", "floor", [[fd, fc, (fc[0], fb[1]), (fd[0], fa[1])]], (0.17, 0.175, 0.185), fl,
                  "the same slab, dry under the passage light", "the passage floor"))
    P.append(Part("beyond", "wall_base", [rect_d(xw(x0, Dp), xw(x1, Dp), 0.0, 0.10, Dp - 0.005)], M.CONCRETE_DK, M.front_plane(Dp - 0.005),
                  "damp line at the wall's foot", "water from mopping and condensation sits here", texture="seam"))
    P.append(Part("beyond", "pour_joint", [rect_d(xw(x0, Dp), xw(x1, Dp), 3.60 - 0.012, 3.60 + 0.012, Dp - 0.002)], M.CONCRETE_DK, M.front_plane(Dp - 0.002),
                  "pour line at 3.6 m (the same lifts as the cross-wall)", "construction joint", texture="seam"))
    if s > 0:
        # the service line: a pipe pair and a cable ladder on strut brackets along the passage, toward Archive
        for i, (h, r, dd) in enumerate(((2.20, 0.075, Dp - 0.25), (2.48, 0.055, Dp - 0.22))):
            P.append(Part("beyond", f"pipe{i}", [rect_d(xw(x0, dd), xw(x1, dd), h - r, h + r, dd)], (0.20, 0.215, 0.24), M.front_plane(dd),
                          ("150 mm" if i == 0 else "100 mm") + " steel pipe, painted", "the service line toward Archive (chilled water supply and return)"))
        P.append(Part("beyond", "tray_rail", [rect_d(xw(x0, Dp - 0.40), xw(x1, Dp - 0.40), 2.95, 3.05, Dp - 0.40)], M.STEEL, M.front_plane(Dp - 0.40),
                      "cable ladder side rail 100 mm, 400 mm wide tray", "carries the data and power cables along the passage"))
        for k, X in enumerate((870.0, 930.0, 990.0)):
            xa = xw(X, Dp - 0.02)
            P.append(Part("beyond", f"strut{k}", [rect_d(xa - 1.0, xa + 1.0, 2.05, 3.10, Dp - 0.02)], M.HOUSING, M.front_plane(Dp - 0.02),
                          "41 mm strut channel bracket, anchored", "holds the pipes and the tray off the wall"))
            for h, r in ((2.20, 0.085), (2.48, 0.065)):
                xp = xw(X, Dp - 0.26)
                P.append(Part("beyond", f"clamp{k}_{int(h * 100)}", [rect_d(xp - 0.7, xp + 0.7, h - r, h + r, Dp - 0.27)], M.DARK, M.front_plane(Dp - 0.27),
                              "pipe clamp", "holds the pipe on the strut"))
    # the passage light on its back wall, fed from above
    lx, ly = (936.0, 300.0) if s > 0 else (18.0, 300.0)
    lw = 0.60 * M.PX_PER_M * M.depth_scale(Dp - 0.12) / 2
    P.append(Part("beyond", "light_body", [[(lx - lw, ly - 1.6), (lx + lw, ly - 1.6), (lx + lw, ly + 1.2), (lx - lw, ly + 1.2)]], M.HOUSING, M.front_plane(Dp - 0.12),
                  "vapour-tight LED fitting 0.6 m", "lights the passage" if s > 0 else "lights the vestibule"))
    P.append(Part("beyond", "light_diffuser", [[(lx - lw + 0.6, ly + 1.2), (lx + lw - 0.6, ly + 1.2), (lx + lw - 0.6, ly + 2.0), (lx - lw + 0.6, ly + 2.0)]], (1, 1, 1), None,
                  "opal diffuser, lit", "the fitting's lens", emit=(0.80, 0.90, 0.96)))
    cx = lx + (lw - 1.5) * (1 if s > 0 else -1)
    P.append(Part("beyond", "light_conduit", [[(cx - 0.4, 100.0), (cx + 0.4, 100.0), (cx + 0.4, ly - 1.6), (cx - 0.4, ly - 1.6)]], M.STEEL, M.front_plane(Dp - 0.04),
                  "20 mm conduit", "feeds the fitting from the ceiling"))
    for p in P:
        if p.emit is None:
            p.clipfn = beyond_wall
    return P


def build_door_end(side):
    door, lamps, f_door, f_pass = lamps_for(side)
    if side > 0:
        cv = Canvas("exit", 770.0, 140.0, 4.0, 4 * 210, 4 * 355)
        x_limit = 990.0
    else:
        cv = Canvas("entry", -40.0, 140.0, 4.0, 4 * 210, 4 * 355)
        x_limit = -30.0
    out = os.path.join(OUT, "exit" if side > 0 else "entry")
    os.makedirs(os.path.join(out, "masks"), exist_ok=True)
    walls = wall_parts(door, lamps)
    fronts, a_far = front_parts(door, x_limit)
    beyond = beyond_parts(door, lamps)
    layers = M.render(walls + fronts + beyond, cv, lamps)
    # contact shadows (alpha on near-black, baked into the layer's transparent floor)
    wl, fr, by = layers["wall"], layers["front"], layers["beyond"]
    # the doorway is alpha 0 in the wall layer by construction (nothing is drawn there)
    wall_sh = wall_contact_shadow(door, cv) * (1 - np.clip(wl["a"], 0, 1))
    front_sh = front_contact_shadow(door, cv) * (1 - np.clip(fr["a"], 0, 1))
    # the lamp's glass is a hole: the game's live lens draws under the guard bars
    lx, ly = lamp_screen(door)
    glass = M.mask_of([("ellipse", lx, ly, 1.9, 2.4)], cv)
    guard = np.clip(sum(fr["masks"][f"lamp_guard{i}"] for i in range(3)), 0, 1)
    glass_hole = np.clip(glass - guard, 0, 1)
    fr["a"] = fr["a"] * (1 - glass_hole)
    fr["masks"]["GLASS_HOLE"] = glass_hole
    for name, lay, sh in (("wall", wl, wall_sh), ("front", fr, front_sh), ("beyond", by, None)):
        a = np.clip(lay["a"], 0, 1)
        rgb = M.to_srgb_u8(lay["lin"])
        if sh is not None:
            # composite the shadow as dark pixels where the layer is empty
            a_total = a + sh * (1 - a)
            rgb = (rgb.astype(np.float64) * (a / np.maximum(a_total, 1e-6))[..., None] + 6.0 * (sh * (1 - a) / np.maximum(a_total, 1e-6))[..., None]).astype(np.uint8)
            a = a_total
            M.save_mask(sh, os.path.join(out, "masks", f"{name}--contact_shadow.png"))
        Image.fromarray(np.dstack([rgb, (a * 255 + 0.5).astype(np.uint8)]), "RGBA").save(os.path.join(out, f"design-{name}.png"))
        M.save_mask(np.clip(lay["a"], 0, 1), os.path.join(out, "masks", f"{name}--ALPHA.png"))
        for n, m in lay["masks"].items():
            M.save_mask(m, os.path.join(out, "masks", f"{name}--{n}.png"))
    spec = {
        "canvas": {"x0": cv.x0, "y0": cv.y0, "ppw": cv.ppw, "w": cv.w, "h": cv.h},
        "door": {"side": side, "x_cross": door.xc, "turn_deg": round(math.degrees(math.atan2(abs(door.U[0]), door.U[2])), 3),
                 "wall_m": door.T_WALL, "leaf_m": [door.LEAF_W, door.LEAF_H, door.LEAF_T], "opening_m": [door.OPEN_W, door.H_OPEN],
                 "hinge_axis_screen_bottom_top": [list(map(lambda v: round(v, 2), M.scr(door.hinge + EY * 0.01))), list(map(lambda v: round(v, 2), M.scr(door.hinge + EY * 2.144)))],
                 "near_jamb_foot": [round(v, 2) for v in door.s(door.A_N, 0.0)], "far_jamb_foot": [round(v, 2) for v in door.s(door.A_F, 0.0)],
                 "far_reveal_back_foot": [round(v, 2) for v in door.s(door.A_F, 0.0, door.T_WALL)],
                 "column_end_face_at_1m": [round(door.s(door.A_END, 1.0, 0.0)[0], 2), round(door.s(door.A_END, 1.0, door.T_WALL)[0], 2)],
                 "back_end_foot": [round(v, 2) for v in door.s(door.A_BACK, 0.0)],
                 "stub_far_a": round(a_far, 3), "status_lamp_screen": [round(lx, 3), round(ly, 3)]},
        "lamps": [{"name": l.name, "pos_m": [round(v, 3) for v in l.pos], "screen": [round(v, 2) for v in M.scr(l.pos)]} for l in lamps],
        "parts": [{"layer": p.layer, "name": p.name, "dims": p.dims, "job": p.job} for p in walls + fronts + beyond],
    }
    M.write_json(os.path.join(out, "spec.json"), spec)
    return door, cv, layers, spec


# ----------------------------------------------------------------------------- the leaf (flat)
LEAF_PPM = 80.0  # 2 px per world px at walkway depth


def leaf_faces():
    """Flat textures of the leaf in its own plane: u from the hinge edge (0) to the latch edge
    (0.914 m), v up from the leaf's bottom (0 .. 2.134 m). Neutral light (albedo times a reference
    exposure, with contact occlusion only); the game shades the swinging mesh per vertex."""
    W, H = int(round(DoorEnd.LEAF_W * LEAF_PPM)), int(round(DoorEnd.LEAF_H * LEAF_PPM))
    out = os.path.join(OUT, "leaf")
    os.makedirs(os.path.join(out, "masks"), exist_ok=True)
    cv = Canvas("leaf", 0.0, 0.0, LEAF_PPM, W, H)  # x in metres (u), y in metres from the TOP

    def R(u0, u1, v0, v1):  # rect in leaf metres, v up
        return [(u0, DoorEnd.LEAF_H - v1), (u1, DoorEnd.LEAF_H - v1), (u1, DoorEnd.LEAF_H - v0), (u0, DoorEnd.LEAF_H - v0)]

    def E(u, v, ru, rv):
        return ("ellipse", u, DoorEnd.LEAF_H - v, ru, rv)

    LW = DoorEnd.LEAF_W
    lever_v = DoorEnd.LEVER_H - 0.010
    backset = 0.070  # 2-3/4 in
    faces = {}
    common_parts = [("leaf", R(0, LW, 0, DoorEnd.LEAF_H), M.GUNSHIP, "1-3/4 in steel leaf, 18 ga faces (ICD 705 3E.11)", "the door")]
    room = common_parts + [
        ("rose", E(LW - backset, lever_v, 0.034, 0.034), M.STEEL, "lever rose 68 mm", "lever trim, free egress from the room"),
        ("lever", R(LW - backset - 0.130, LW - backset, lever_v - 0.010, lever_v + 0.010), M.STEEL_WORN, "lever 130 mm, returned toward the hinge", "opens the latch from inside"),
        ("thumbturn_rose", E(LW - backset, lever_v + 0.105, 0.026, 0.026), M.STEEL, "deadbolt thumbturn rose", "FF-L-2890 deadbolt, thrown from inside"),
        ("thumbturn", R(LW - backset - 0.006, LW - backset + 0.006, lever_v + 0.085, lever_v + 0.125), M.STEEL_WORN, "thumbturn", "throws the deadbolt"),
        ("hand_wear", E(LW - backset - 0.05, lever_v, 0.11, 0.09), M.GUNSHIP, "worn paint round the lever (no geometry)", "where hands push the leaf"),
    ]
    out_exit = common_parts + [
        ("kick", R(0.04, LW - 0.04, 0.0, 0.254), M.STEEL, "10 in steel kick plate", "the push side (outside) takes the carts and boots"),
        ("seal", R(0.0, LW, 0.0, 0.018), M.RUBBER, "automatic door bottom", "drops onto the threshold when shut (acoustic seal)"),
        ("rose", E(LW - backset, lever_v, 0.034, 0.034), M.STEEL, "lever rose 68 mm with a key cylinder", "outside lever trim (access-controlled, ICD 705 3E.1b)"),
        ("cylinder", E(LW - backset, lever_v, 0.012, 0.012), M.DARK, "key cylinder face", "access control override"),
        ("lever", R(LW - backset - 0.130, LW - backset, lever_v - 0.010, lever_v + 0.010), M.STEEL_WORN, "lever 130 mm", "opens the latch when the reader releases it"),
    ]
    out_entry = common_parts + [
        ("kick", R(0.04, LW - 0.04, 0.0, 0.254), M.STEEL, "10 in steel kick plate", "the push side (outside)"),
        ("seal", R(0.0, LW, 0.0, 0.018), M.RUBBER, "automatic door bottom", "acoustic seal"),
        ("rose", E(LW - backset, lever_v, 0.034, 0.034), M.STEEL, "lever rose 68 mm", "outside lever trim"),
        ("lever", R(LW - backset - 0.130, LW - backset, lever_v - 0.010, lever_v + 0.010), M.STEEL_WORN, "lever 130 mm", "opens the latch"),
        ("lock_housing", R(LW - backset - 0.050, LW - backset + 0.050, 1.360, 1.520), M.HOUSING, "combination lock housing 100 x 160 mm", "the primary entrance's FF-L-2740 lock (ICD 705 3E.1a)"),
        ("lock_dial_ring", E(LW - backset, 1.415, 0.040, 0.040), M.STEEL, "spin-dial ring", "FF-L-2740 combination dial"),
        ("lock_dial", E(LW - backset, 1.415, 0.031, 0.031), M.DARK, "spin dial (no graduations painted: too small to read)", "sets the combination"),
        ("lock_window", R(LW - backset - 0.016, LW - backset + 0.016, 1.476, 1.494), M.DARK, "display window, blank", "the lock's display"),
    ]
    edge = [("edge", [(0, 0), (DoorEnd.LEAF_T, 0), (DoorEnd.LEAF_T, DoorEnd.LEAF_H), (0, DoorEnd.LEAF_H)], M.GUNSHIP, "latch edge, 44 mm", "the leaf's free edge"),
            ("lock_front", R(0.008, DoorEnd.LEAF_T - 0.008, lever_v - 0.10, lever_v + 0.15), M.STEEL, "mortise lock front 25 x 250 mm", "latch and deadbolt")]
    E_REF = 1.0
    for fname, parts in (("room", room), ("out-exit", out_exit), ("out-entry", out_entry)):
        lin = np.zeros((H, W, 3))
        masks = {}
        for pname, poly, alb, dims, job in parts:
            m = M.mask_of([poly], cv)
            col = np.array(alb) * E_REF
            if pname == "hand_wear":
                col = np.array(M.GUNSHIP) * 1.05
            lin = lin * (1 - m[..., None]) + col * m[..., None]
            masks[pname] = m
        # hardware casts a little contact occlusion on the leaf (light from above: shadow just under it)
        hw = np.zeros((H, W))
        for k in ("rose", "lever", "thumbturn_rose", "lock_housing"):
            if k in masks:
                hw = np.maximum(hw, masks[k])
        sh = np.roll(hw, 2, axis=0) * (1 - hw)
        lin = lin * (1 - 0.35 * sh[..., None])
        Image.fromarray(M.to_srgb_u8(lin)).save(os.path.join(out, f"design-{fname}.png"))
        for n, m in masks.items():
            M.save_mask(m, os.path.join(out, "masks", f"{fname}--{n}.png"))
        faces[fname] = {"parts": [{"name": p[0], "dims": p[3], "job": p[4]} for p in parts]}
    ew = max(2, int(round(DoorEnd.LEAF_T * LEAF_PPM)) + 1)
    ecv = Canvas("edge", 0.0, 0.0, LEAF_PPM, ew, H)
    lin = np.zeros((H, ew, 3))
    for pname, poly, alb, dims, job in edge:
        m = M.mask_of([poly], ecv)
        lin = lin * (1 - m[..., None]) + np.array(alb) * E_REF * m[..., None]
    Image.fromarray(M.to_srgb_u8(lin)).save(os.path.join(out, "design-edge.png"))
    faces["edge"] = {"parts": [{"name": p[0], "dims": p[3], "job": p[4]} for p in edge]}
    M.write_json(os.path.join(out, "spec.json"), {"ppm": LEAF_PPM, "size_px": [W, H], "edge_px": [ew, H], "u": "hinge edge 0 -> latch edge", "v": "up", "reference_exposure": E_REF, "faces": faces})


# ----------------------------------------------------------------------------- the container
def container():
    """GSA Class 5 four-drawer legal security container, gray, single-lock design (GSA Class 5
    filing cabinet sheet: 58-1/2 in H x 20-7/8 in W x 33-1/2 in D, about 1195 lb)."""
    door, lamps, f_door, _ = lamps_for(1)
    Hc, Wc, Dc = 1.486, 0.530, 0.851
    cx = CONTAINER_X / M.PX_PER_M
    d0 = CONTAINER_FRONT_D
    cv = Canvas("container", CONTAINER_X - 22.0, 440.0 - 70.0, 4.0, 4 * 44, 4 * 76)
    out = os.path.join(OUT, "container")
    os.makedirs(os.path.join(out, "masks"), exist_ok=True)

    def P3(x, h, d):
        return np.array([x, h, d])

    def poly(*pts):
        return [M.scr(p) for p in pts]

    xl, xr = cx - Wc / 2, cx + Wc / 2
    fr = M.front_plane(d0)
    side = Plane(P3(xl, 0, d0), np.array([0, 0, 1.0]), EY, np.array([-1.0, 0, 0]))
    top = Plane(P3(xl, Hc, d0), np.array([1.0, 0, 0]), np.array([0, 0, 1.0]), EY)
    parts = []
    parts.append(Part("container", "side", [poly(P3(xl, 0, d0), P3(xl, 0, d0 + Dc), P3(xl, Hc, d0 + Dc), P3(xl, Hc, d0))], M.CONTAINER_GRAY, side,
                      "side panel, 0.85 m deep", "the body (welded steel)"))
    parts.append(Part("container", "top", [poly(P3(xl, Hc, d0), P3(xr, Hc, d0), P3(xr, Hc, d0 + Dc), P3(xl, Hc, d0 + Dc))], M.CONTAINER_GRAY, top,
                      "top", "the body"))
    parts.append(Part("container", "front", [poly(P3(xl, 0, d0), P3(xr, 0, d0), P3(xr, Hc, d0), P3(xl, Hc, d0))], M.CONTAINER_GRAY, fr,
                      "front frame 0.53 x 1.486 m", "carries the four drawers"))
    base_h = 0.06
    parts.append(Part("container", "base", [poly(P3(xl + 0.01, 0, d0 - 0.001), P3(xr - 0.01, 0, d0 - 0.001), P3(xr - 0.01, base_h, d0 - 0.001), P3(xl + 0.01, base_h, d0 - 0.001))], M.HOUSING, M.front_plane(d0 - 0.001),
                      "recessed base", "stands it on the floor"))
    dh = (Hc - base_h - 0.03) / 4
    for i in range(4):
        h0 = base_h + i * dh + 0.006
        h1 = h0 + dh - 0.012
        parts.append(Part("container", f"drawer{i}", [poly(P3(xl + 0.018, h0, d0 - 0.004), P3(xr - 0.018, h0, d0 - 0.004), P3(xr - 0.018, h1, d0 - 0.004), P3(xl + 0.018, h1, d0 - 0.004))], M.CONTAINER_GRAY, M.front_plane(d0 - 0.004),
                          "drawer face 0.49 x 0.33 m (10-1/4 in deep inside)", "a legal-size drawer"))
        hy = h1 - 0.075
        parts.append(Part("container", f"pull{i}", [poly(P3(cx - 0.11, hy - 0.022, d0 - 0.02), P3(cx + 0.11, hy - 0.022, d0 - 0.02), P3(cx + 0.11, hy + 0.022, d0 - 0.02), P3(cx - 0.11, hy + 0.022, d0 - 0.02))], M.STEEL, M.front_plane(d0 - 0.02),
                          "drawer pull 220 mm", "opens the drawer once the lock is open"))
        parts.append(Part("container", f"pull_recess{i}", [poly(P3(cx - 0.10, hy + 0.012, d0 - 0.021), P3(cx + 0.10, hy + 0.012, d0 - 0.021), P3(cx + 0.10, hy + 0.022, d0 - 0.021), P3(cx - 0.10, hy + 0.022, d0 - 0.021))], M.DARK, M.front_plane(d0 - 0.021),
                          "finger recess", "the pull's grip"))
        parts.append(Part("container", f"card{i}", [poly(P3(cx - 0.06, hy - 0.10, d0 - 0.006), P3(cx + 0.06, hy - 0.10, d0 - 0.006), P3(cx + 0.06, hy - 0.055, d0 - 0.006), P3(cx - 0.06, hy - 0.055, d0 - 0.006))], M.STEEL, M.front_plane(d0 - 0.006),
                          "label holder 120 x 45 mm, blank card", "names the drawer (blank: too small to letter)"))
    top_h0 = base_h + 3 * dh + 0.006
    lh = top_h0 + dh - 0.075 - 0.14
    lc = M.scr(P3(cx + 0.15, lh, d0 - 0.03))
    parts.append(Part("container", "lock_ring", [("ellipse", lc[0], lc[1], 0.043 * M.PX_PER_M, 0.043 * M.PX_PER_M)], M.STEEL, M.front_plane(d0 - 0.03),
                      "FF-L-2740 spin-dial ring", "the single lock that controls all four drawers"))
    parts.append(Part("container", "lock_dial", [("ellipse", lc[0], lc[1], 0.033 * M.PX_PER_M, 0.033 * M.PX_PER_M)], M.DARK, M.front_plane(d0 - 0.035),
                      "spin dial (graduations too small to read: none painted)", "sets the combination"))
    lamps_c = [l for l in lamps]
    lay = M.render(parts, cv, lamps_c)["container"]
    # floor contact shadow from the footprint (darkest at the contact line), on the walkway floor
    X, Y = cv.grid()
    A, B = cv.rays()
    tt = (0.0 - A[1]) / np.where(np.abs(B[..., 1]) < 1e-9, -1e-9, B[..., 1])
    Pf = A + B * tt[..., None]
    dx = np.maximum(np.maximum(xl - Pf[..., 0], Pf[..., 0] - xr), 0)
    dz = np.maximum(np.maximum(d0 - Pf[..., 2], Pf[..., 2] - (d0 + Dc)), 0)
    dist = np.hypot(dx, dz)
    sh = 0.62 * np.exp(-dist / 0.07) * (Y > 400)
    a = np.clip(lay["a"], 0, 1)
    sh = sh * (1 - a)
    rgb = M.to_srgb_u8(lay["lin"])
    a_total = a + sh
    rgb = (rgb.astype(np.float64) * (a / np.maximum(a_total, 1e-6))[..., None] + 6.0 * (sh / np.maximum(a_total, 1e-6))[..., None]).astype(np.uint8)
    Image.fromarray(np.dstack([rgb, (a_total * 255 + 0.5).astype(np.uint8)]), "RGBA").save(os.path.join(out, "design-container.png"))
    M.save_mask(a, os.path.join(out, "masks", "container--ALPHA.png"))
    M.save_mask(sh, os.path.join(out, "masks", "container--contact_shadow.png"))
    for n, m in lay["masks"].items():
        M.save_mask(m, os.path.join(out, "masks", f"container--{n}.png"))
    M.write_json(os.path.join(out, "spec.json"), {
        "canvas": {"x0": cv.x0, "y0": cv.y0, "ppw": cv.ppw, "w": cv.w, "h": cv.h},
        "centre_x": CONTAINER_X, "front_depth_m": d0, "size_m": [Wc, Hc, Dc],
        "screen_front_left_right": [round(M.scr(P3(xl, 0, d0))[0], 2), round(M.scr(P3(xr, 0, d0))[0], 2)],
        "screen_back_left_foot": [round(v, 2) for v in M.scr(P3(xl, 0, d0 + Dc))],
        "lock_screen": [round(lc[0], 2), round(lc[1], 2)], "lock_height_m": round(lh, 3),
        "parts": [{"name": p.name, "dims": p.dims, "job": p.job} for p in parts],
    })


def main():
    for side in (1, -1):
        door, cv, layers, spec = build_door_end(side)
        print(side, spec["door"])
    leaf_faces()
    container()


if __name__ == "__main__":
    main()
