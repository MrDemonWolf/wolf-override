"""Procedural side-view mannequin rigs for WOLF//OVERRIDE walk-cycle pose guides.

Engineer units: H = figure height (1.0). WOLF units: R = reference px of
wolf-side-right.png (1550 R = nose-to-tail length). Coordinates: x forward
(screen right), y up, origin on the ground under the pelvis / body centre.

Feet are driven by IK from planted ground anchors, so the guide itself has
zero foot slide: during stance a foot's anchor moves back at exactly
stride/N per frame, which is the camera speed at the no-slide frame rate.
"""
import math
import numpy as np

TAU = 2 * math.pi


def smooth(t):
    t = min(max(t, 0.0), 1.0)
    return t * t * (3 - 2 * t)


def ik2(a, b, l1, l2, bend_sign):
    """Two-bone IK from root a to target b. bend_sign +1 puts the middle joint
    forward (+x side of the a->b line, like a human knee), -1 backward."""
    a = np.asarray(a, float); b = np.asarray(b, float)
    d = b - a
    dist = float(np.hypot(*d))
    reach = l1 + l2
    clamped = False
    if dist > reach * 0.9995:
        b = a + d / dist * reach * 0.9995
        d = b - a; dist = reach * 0.9995; clamped = True
    dist = max(dist, abs(l1 - l2) + 1e-6)
    cos_a = (l1 * l1 + dist * dist - l2 * l2) / (2 * l1 * dist)
    ang = math.acos(min(1, max(-1, cos_a)))
    base = math.atan2(d[1], d[0])
    # choose the solution whose middle joint is on the requested side
    cands = []
    for s in (+1, -1):
        th = base + s * ang
        m = a + l1 * np.array([math.cos(th), math.sin(th)])
        cands.append(m)
    # side test: cross product sign relative to a->b, convert to "forward"
    def fwd(m):
        # perpendicular of downward-ish leg pointing toward +x
        perp = np.array([-d[1], d[0]]) / dist
        if perp[0] < 0:
            perp = -perp
        return float(np.dot(m - a, perp))
    m = max(cands, key=fwd) if bend_sign > 0 else min(cands, key=fwd)
    return m, b, clamped


# ---------------------------------------------------------------- engineer
ENG = dict(
    hip_h=0.530, thigh=0.245, shin=0.238, ankle_h=0.050,
    heel=0.040, toe=0.115,  # ankle to heel back / toe front (boot)
    spine=0.300, neck=0.045, head_r=0.062,
    uarm=0.180, farm=0.155, hand=0.075,
)

GAITS = {
    # duty: stance fraction; step: stride/2 in H; bob: total vertical range in H
    'walk': dict(n=12, duty=0.60, stride=0.92, bob=0.025, lean=4.0, td_front=0.40,
                 heel_pitch=16.0, toeoff_pitch=-34.0, lift=0.075, arm=19.0, elbow=18.0,
                 arm_bias=-4.0, kick=0.0),
    'jog': dict(n=12, duty=0.36, stride=1.56, bob=0.035, lean=11.0, td_front=0.38,
                heel_pitch=6.0, toeoff_pitch=-48.0, lift=0.20, arm=30.0, elbow=76.0,
                arm_bias=-6.0, kick=0.10),
}


def eng_leg_state(g, phi, stride):
    """Foot state for one leg at cycle phase phi in [0,1). phi=0 is heel strike."""
    p = ENG
    duty = g['duty']
    travel = duty * stride
    x_td = g['td_front'] * travel          # flat-foot ankle x at touchdown
    x_lo = x_td - travel                   # flat-foot ankle x at toe-off
    hp = math.radians(g['heel_pitch']); tp = math.radians(g['toeoff_pitch'])

    def planted(ax, pitch):
        # ankle position for a foot whose flat placement has ankle at ax,
        # rotated about heel (pitch>0, toe up) or toe (pitch<0, heel up)
        if pitch >= 0:
            pivot = np.array([ax - p['heel'], 0.0])
            off = np.array([p['heel'], p['ankle_h']])
        else:
            pivot = np.array([ax + p['toe'], 0.0])
            off = np.array([-p['toe'], p['ankle_h']])
        c, s = math.cos(pitch), math.sin(pitch)
        rot = np.array([c * off[0] - s * off[1], s * off[0] + c * off[1]])
        return pivot + rot

    if phi < duty:
        u = phi / duty
        ax = x_td - u * travel
        if u < 0.14:
            pitch = hp * (1 - smooth(u / 0.14))
        elif u > 0.52:
            pitch = tp * smooth((u - 0.52) / 0.48) ** 1.3
        else:
            pitch = 0.0
        return planted(ax, pitch), pitch, True, ax
    # swing
    u = (phi - duty) / (1 - duty)
    a0 = planted(x_lo, tp); a1 = planted(x_td, hp)
    # horizontal: slow start (heel kicks up), fast middle
    ux = smooth(u) ** (1.0 + 0.6 * g['kick'] / 0.1 if g['kick'] else 1.0)
    x = a0[0] + (a1[0] - a0[0]) * ux
    y = a0[1] + (a1[1] - a0[1]) * smooth(u) + g['lift'] * math.sin(math.pi * u) ** 1.2
    if g['kick']:
        x -= g['kick'] * math.sin(math.pi * min(1, u * 1.6))  # heel back toward seat
        y += g['kick'] * 0.6 * math.sin(math.pi * min(1, u * 1.4))
    # plantarflex through early swing (toes trail the shin), then dorsiflex for touchdown
    deep = tp - math.radians(30 if g['kick'] else 14)
    if u < 0.35:
        pitch = tp + (deep - tp) * smooth(u / 0.35)
    else:
        pitch = deep + (hp - deep) * smooth((u - 0.35) / 0.65)
    return np.array([x, y]), pitch, False, None


def _curve(kind, g, phi):
    ps = (phi * 2) % 1.0  # step phase
    if kind == 'walk':
        # contact mid, down (lowest) 1/6 into the step, up (highest) 4/6
        c = math.cos(TAU * (ps - 0.667))
    else:
        # lowest at mid stance, highest in flight
        c = math.cos(TAU * (ps - g['duty'] - 0.5))
    return 0.5 + 0.5 * c


_BASE = {}


def eng_hip_height(kind, g, f, n):
    """Designed bob curve (amplitude g['bob']) lifted as high as both planted
    legs allow, so no frame is clamped and the bob stays exactly as designed."""
    key = (kind, n)
    if key not in _BASE:
        L = (ENG['thigh'] + ENG['shin']) * 0.993
        base = ENG['hip_h']
        for k in range(n):
            ph = k / n
            for off in (0.0, 0.5):
                ank, pitch, st, _ = eng_leg_state(g, (ph + off) % 1.0, g['stride'])
                if st:
                    hm = ank[1] + math.sqrt(max(0, L * L - ank[0] ** 2))
                    base = min(base, hm - g['bob'] * _curve(kind, g, ph))
        _BASE[key] = base
    return _BASE[key] + g['bob'] * _curve(kind, g, f / n)


def eng_pose(kind, f, n=None):
    p = ENG
    if kind == 'idle':
        return eng_idle(f, n or 8)
    g = GAITS[kind]
    n = n or g['n']
    phi = f / n
    stride = g['stride']
    # near (right) leg strikes at 0, far (left) at 0.5
    legs = {}
    for name, off in (('near', 0.0), ('far', 0.5)):
        legs[name] = eng_leg_state(g, (phi + off) % 1.0, stride)
    hip_x = 0.0
    hip_y = eng_hip_height(kind, g, f, n)
    lean = math.radians(g['lean'])
    hip = np.array([hip_x, hip_y])
    J = {'hip': hip, 'kind': kind, 'f': f}
    for name in ('near', 'far'):
        ank, pitch, st, ax = legs[name]
        knee, ank2, cl = ik2(hip, ank, p['thigh'], p['shin'], +1)
        J[name + '_knee'] = knee; J[name + '_ankle'] = ank2
        J[name + '_pitch'] = pitch; J[name + '_stance'] = st; J[name + '_clamped'] = cl
        c, s = math.cos(pitch), math.sin(pitch)
        def tr(v):
            return ank2 + np.array([c * v[0] - s * v[1], s * v[0] + c * v[1]])
        J[name + '_heel'] = tr(np.array([-p['heel'], -p['ankle_h']]))
        J[name + '_toe'] = tr(np.array([p['toe'], -p['ankle_h']]))
        J[name + '_heel_top'] = tr(np.array([-p['heel'], 0.03]))
        J[name + '_toe_top'] = tr(np.array([p['toe'] * 0.85, 0.0]))
    # torso
    sh = hip + p['spine'] * np.array([math.sin(lean), math.cos(lean)])
    # slight counter-rotation: shoulders dip with the step
    J['shoulder'] = sh
    neck = sh + p['neck'] * np.array([math.sin(lean * 0.5), math.cos(lean * 0.5)])
    J['neck'] = neck
    J['head'] = neck + np.array([0.012, p['head_r'] * 1.05])
    # arms: opposite to same-side leg. near arm pairs with far leg phase
    for name, off in (('near', 0.5), ('far', 0.0)):
        ph = (phi + off) % 1.0
        # arm forward when the opposite... leg forward: at heel strike (ph=0) arm is fwd max
        swing = math.radians(g['arm']) * math.cos(TAU * (ph - 0.03)) + math.radians(g['arm_bias'])
        # arm angle measured from straight down, positive = forward
        ua = swing
        elb = sh + p['uarm'] * np.array([math.sin(ua), -math.cos(ua)])
        bend = math.radians(g['elbow']) * (1.0 + (0.35 if kind == 'walk' else 0.12) * max(0, math.cos(TAU * (ph - 0.03))))
        fa = ua + bend
        wr = elb + p['farm'] * np.array([math.sin(fa), -math.cos(fa)])
        hd = wr + p['hand'] * np.array([math.sin(fa), -math.cos(fa)])
        J[name + '_elbow'] = elb; J[name + '_wrist'] = wr; J[name + '_hand'] = hd
    J['stride'] = stride; J['n'] = n
    return J


def eng_idle(f, n=8):
    p = ENG
    t = f / n
    br = 0.5 - 0.5 * math.cos(TAU * t)            # 0..1..0 breath
    sway = 0.006 * math.sin(TAU * t)               # tiny weight shift
    hip = np.array([sway, p['hip_h'] - 0.012 - 0.004 * br])
    J = {'hip': hip, 'kind': 'idle', 'f': f}
    stance = {'near': 0.055, 'far': -0.045}
    for name, ax in stance.items():
        ank = np.array([ax, p['ankle_h']])
        knee, ank2, cl = ik2(hip, ank, p['thigh'], p['shin'], +1)
        J[name + '_knee'] = knee; J[name + '_ankle'] = ank2; J[name + '_pitch'] = 0.0
        J[name + '_stance'] = True; J[name + '_clamped'] = cl
        J[name + '_heel'] = ank2 + np.array([-p['heel'], -p['ankle_h']])
        J[name + '_toe'] = ank2 + np.array([p['toe'], -p['ankle_h']])
        J[name + '_heel_top'] = ank2 + np.array([-p['heel'], 0.03])
        J[name + '_toe_top'] = ank2 + np.array([p['toe'] * 0.85, 0.0])
    lean = math.radians(2.0)
    sh = hip + (p['spine'] + 0.010 * br) * np.array([math.sin(lean), math.cos(lean)])
    J['shoulder'] = sh
    J['neck'] = sh + np.array([0.002, p['neck']])
    J['head'] = J['neck'] + np.array([0.012, p['head_r'] * 1.05 + 0.002 * br])
    J['chest_scale'] = 1.0 + 0.05 * br
    for name, a0 in (('near', 4.0), ('far', -3.0)):
        ua = math.radians(a0 + 1.5 * br)
        elb = sh + p['uarm'] * np.array([math.sin(ua), -math.cos(ua)])
        fa = ua + math.radians(14 + 2 * br)
        wr = elb + p['farm'] * np.array([math.sin(fa), -math.cos(fa)])
        hd = wr + p['hand'] * np.array([math.sin(fa), -math.cos(fa)])
        J[name + '_elbow'] = elb; J[name + '_wrist'] = wr; J[name + '_hand'] = hd
    J['stride'] = 0.0; J['n'] = n
    return J


# ---------------------------------------------------------------- WOLF
# Reference-image units (R). Ground at 0. Measured from wolf-side-right.png.
WLF = dict(
    shoulder=np.array([200.0, 470.0]), hip=np.array([-185.0, 520.0]),
    humerus=205.0, radius=235.0, metacarp=75.0,
    femur=215.0, tibia=230.0, metatarsus=150.0,
    paw_h=38.0,
)

WGAITS = {
    # Hildebrand: walk is lateral-sequence (hind then same-side fore), D ~ 25%,
    # duty ~ 0.63 (PMC5015230: walking dogs stance 62.5%). Trot: diagonal pairs,
    # duty ~ 0.45 (trotting dogs stance 46.9%), short suspension.
    'walk': dict(n=12, duty=0.64, swing_deg=23.0, lift=60.0, bob=7.0, head_nod=10.0,
                 phases={'RH': 0.0, 'RF': 0.25, 'LH': 0.5, 'LF': 0.75}),
    'trot': dict(n=12, duty=0.44, swing_deg=25.0, lift=95.0, bob=18.0, head_nod=6.0,
                 phases={'RH': 0.0, 'LF': 0.03, 'LH': 0.5, 'RF': 0.53}),
}


def wolf_stride(g):
    w = WLF
    leg = w['humerus'] + w['radius'] + w['metacarp']
    travel = 2 * leg * math.sin(math.radians(g['swing_deg']))
    return travel / g['duty'], travel


def wolf_pose(kind, f, n=None):
    w = WLF
    if kind == 'idle':
        return wolf_idle(f, n or 8)
    g = WGAITS[kind]
    n = n or g['n']
    phi = f / n
    stride, travel = wolf_stride(g)
    # body bob: two dips per cycle (each diagonal/side support)
    bob = -g['bob'] * 0.5 * (1 + math.cos(TAU * 2 * (phi - (0.12 if kind == 'trot' else 0.1))))
    pitch_deg = 1.5 * math.sin(TAU * phi)  # slight rocking
    J = {'kind': kind, 'f': f, 'n': n, 'stride': stride}
    body = body_frame(bob, pitch_deg)
    J.update(body)
    for leg, off in g['phases'].items():
        ph = (phi - off) % 1.0
        fore = leg.endswith('F')
        root = J['shoulder'] if fore else J['hip']
        rest_x = (w['shoulder'][0] + 10) if fore else (w['hip'][0] - 20)
        x_td = rest_x + travel * 0.5
        if ph < g['duty']:
            u = ph / g['duty']
            px = x_td - u * travel
            py = 0.0
            st = True
        else:
            u = (ph - g['duty']) / (1 - g['duty'])
            x0 = x_td - travel
            px = x0 + travel * smooth(u)
            py = g['lift'] * math.sin(math.pi * u) ** (1.4 if fore else 1.1)
            st = False
        paw = np.array([px, py + w['paw_h'] * 0.55])
        J[leg + '_stance'] = st
        J[leg + '_paw'] = paw
        J[leg + '_contact_x'] = px if st else None
        if fore:
            # carpus above paw; flexes backward in swing
            flex = 0.0 if st else math.sin(math.pi * u) * 1.1
            carp = paw + w['metacarp'] * np.array([-math.sin(flex) * 0.9, math.cos(flex)])
            elbow, carp2, cl = ik2(root, carp, w['humerus'], w['radius'], -1)
            J[leg + '_elbow'] = elbow; J[leg + '_carpus'] = carp2; J[leg + '_clamped'] = cl
        else:
            # hock behind and above paw; metatarsus leans forward-down
            tilt = math.radians(14) + (0 if st else math.sin(math.pi * u) * 0.5)
            if st:
                tilt += math.radians(18) * (u - 0.5)
            hock = paw + w['metatarsus'] * np.array([-math.sin(tilt), math.cos(tilt)])
            stifle, hock2, cl = ik2(root, hock, w['femur'], w['tibia'], +1)
            J[leg + '_stifle'] = stifle; J[leg + '_hock'] = hock2; J[leg + '_clamped'] = cl
    # head nods with the forelimbs (dip after each fore strike)
    nod = g['head_nod'] * math.cos(TAU * 2 * (phi - 0.3))
    J['head_dy'] = nod
    J['tail_phase'] = phi
    J['tail_amp'] = 6.0 if kind == 'walk' else 9.0
    return J


def body_frame(bob, pitch_deg, chest=1.0, head_dy=0.0):
    w = WLF
    th = math.radians(pitch_deg)
    c, s = math.cos(th), math.sin(th)
    def T(v):
        v = np.asarray(v, float)
        return np.array([c * v[0] - s * v[1], s * v[0] + c * v[1] + bob])
    return dict(T=T, shoulder=T(w['shoulder']), hip=T(w['hip']), bob=bob, chest=chest)


def wolf_idle(f, n=8):
    t = f / n
    br = 0.5 - 0.5 * math.cos(TAU * t)
    J = {'kind': 'idle', 'f': f, 'n': n, 'stride': 0.0}
    J.update(body_frame(-3.0 * br, 0.0, chest=1.0 + 0.035 * br))
    w = WLF
    stance = {'RH': -150.0, 'LH': -230.0, 'RF': 235.0, 'LF': 175.0}
    for leg, px in stance.items():
        fore = leg.endswith('F')
        paw = np.array([px, w['paw_h'] * 0.55])
        J[leg + '_stance'] = True; J[leg + '_paw'] = paw; J[leg + '_contact_x'] = px
        if fore:
            carp = paw + np.array([0, w['metacarp']])
            elbow, carp2, cl = ik2(J['shoulder'], carp, w['humerus'], w['radius'], -1)
            J[leg + '_elbow'] = elbow; J[leg + '_carpus'] = carp2; J[leg + '_clamped'] = cl
        else:
            tilt = math.radians(14)
            hock = paw + w['metatarsus'] * np.array([-math.sin(tilt), math.cos(tilt)])
            stifle, hock2, cl = ik2(J['hip'], hock, w['femur'], w['tibia'], +1)
            J[leg + '_stifle'] = stifle; J[leg + '_hock'] = hock2; J[leg + '_clamped'] = cl
    J['head_dy'] = 4.0 * math.sin(TAU * t)
    J['tail_phase'] = t
    J['tail_amp'] = 4.0
    return J
