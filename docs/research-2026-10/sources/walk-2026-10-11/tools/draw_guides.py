"""Render mannequin pose-guide sheets (Codex edit targets) and their geometry JSON."""
import json, math, os, sys
import numpy as np
from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(__file__))
import rig

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
OUT = os.path.join(ROOT, 'guides')
KEY = (255, 0, 255)
SS = 3  # supersample

C_NEAR = (172, 184, 200); C_FAR = (84, 94, 110); C_BODY = (128, 139, 155)
C_HEAD = (150, 160, 176); C_MARK = (230, 236, 244)

ENG_H = 460.0          # guide px per H
ENG_BASE = 520         # baseline row in cell
WOLF_S = 690.0 / 1550  # guide px per R
WOLF_BASE = 448
WOLF_CX_OFF = 55       # body centre right of cell centre

LAYOUTS = {
    # kind: (W, H, cols, rows)
    'eng-gait': (1448, 1086, 3, 2),
    'eng-idle': (1448, 1086, 4, 2),
    'wolf': (1672, 941, 2, 2),
}


def cells(W, Hh, cols, rows):
    xs = [round(i * W / cols) for i in range(cols + 1)]
    ys = [round(j * Hh / rows) for j in range(rows + 1)]
    out = []
    for j in range(rows):
        for i in range(cols):
            out.append((xs[i], ys[j], xs[i + 1], ys[j + 1]))
    return out


class Pen:
    def __init__(self, draw, ox, oy, scale):
        self.d = draw; self.ox = ox; self.oy = oy; self.s = scale

    def P(self, v):
        return ((self.ox + v[0] * self.s) * SS, (self.oy - v[1] * self.s) * SS)

    def capsule(self, a, b, w, col):
        a = self.P(a); b = self.P(b); r = w * self.s * SS / 2
        self.d.line([a, b], fill=col, width=max(1, int(round(2 * r))))
        for c in (a, b):
            self.d.ellipse([c[0] - r, c[1] - r, c[0] + r, c[1] + r], fill=col)

    def taper(self, a, b, wa, wb, col):
        a = np.asarray(a, float); b = np.asarray(b, float)
        d = b - a; n = np.array([-d[1], d[0]]) / (np.hypot(*d) + 1e-9)
        pts = [a + n * wa / 2, b + n * wb / 2, b - n * wb / 2, a - n * wa / 2]
        self.poly(pts, col)
        self.disc(a, wa / 2, col); self.disc(b, wb / 2, col)

    def poly(self, pts, col):
        self.d.polygon([self.P(p) for p in pts], fill=col)

    def disc(self, c, r, col):
        c = self.P(c); r = r * self.s * SS
        self.d.ellipse([c[0] - r, c[1] - r, c[0] + r, c[1] + r], fill=col)

    def ellipse(self, c, rx, ry, col):
        c = self.P(c); rx *= self.s * SS; ry *= self.s * SS
        self.d.ellipse([c[0] - rx, c[1] - ry, c[0] + rx, c[1] + ry], fill=col)


# ------------------------------------------------------------ engineer
def draw_engineer(pen, J):
    p = rig.ENG
    def leg(name, col):
        pen.taper(J['hip'], J[name + '_knee'], 0.082, 0.066, col)
        pen.taper(J[name + '_knee'], J[name + '_ankle'], 0.066, 0.056, col)
        boot = [J[name + '_heel'], J[name + '_toe'], J[name + '_toe_top'], J[name + '_heel_top']]
        pen.poly(boot, col)
        pen.disc(J[name + '_ankle'], 0.034, col)
    def arm(name, col):
        pen.taper(J['shoulder'] + np.array([0, -0.02]), J[name + '_elbow'], 0.062, 0.050, col)
        pen.taper(J[name + '_elbow'], J[name + '_wrist'], 0.050, 0.042, col)
        pen.taper(J[name + '_wrist'], J[name + '_hand'], 0.050, 0.040, col)
    arm('far', C_FAR)
    leg('far', C_FAR)
    # torso: pelvis to shoulders, chest wider
    hip = J['hip']; sh = J['shoulder']
    up = (sh - hip) / np.hypot(*(sh - hip)); rt = np.array([up[1], -up[0]])
    cs = J.get('chest_scale', 1.0)
    pts = [hip + rt * 0.060 - up * 0.035, hip - rt * 0.058 - up * 0.035,
           sh - rt * 0.070 * cs - up * 0.04, sh - rt * 0.062 + up * 0.015,
           sh + rt * 0.055 + up * 0.015, sh + rt * 0.068 * cs - up * 0.06]
    pen.poly(pts, C_BODY)
    pen.disc(sh - up * 0.01, 0.060, C_BODY)
    pen.capsule(J['shoulder'], J['neck'], 0.050, C_BODY)
    leg('near', C_NEAR)
    # head: circle plus a nose wedge facing right, light eye mark
    hd = J['head']; r = p['head_r']
    pen.disc(hd, r, C_HEAD)
    pen.poly([hd + np.array([0.035, 0.02]), hd + np.array([r + 0.016, -0.012]), hd + np.array([0.03, -0.04])], C_HEAD)
    pen.disc(hd + np.array([0.034, 0.008]), 0.009, C_MARK)
    arm('near', C_NEAR)


# ------------------------------------------------------------ WOLF
TORSO = [(-330, 575), (-150, 592), (50, 588), (190, 612), (290, 650), (330, 600), (310, 430), (230, 300),
         (90, 292), (-50, 342), (-190, 362), (-320, 415), (-372, 505)]
NECK = [(220, 600), (330, 680), (460, 650), (430, 520), (300, 430)]


def draw_wolf(pen, J):
    w = rig.WLF; T = J['T']
    hd = J.get('head_dy', 0.0)
    def leg(name, col):
        fore = name.endswith('F')
        root = J['shoulder'] if fore else J['hip']
        paw = J[name + '_paw']
        if fore:
            pen.taper(root, J[name + '_elbow'], 78, 56, col)
            pen.taper(J[name + '_elbow'], J[name + '_carpus'], 50, 40, col)
            pen.taper(J[name + '_carpus'], paw, 40, 36, col)
        else:
            pen.taper(root, J[name + '_stifle'], 120, 64, col)
            pen.taper(J[name + '_stifle'], J[name + '_hock'], 56, 40, col)
            pen.taper(J[name + '_hock'], paw, 40, 34, col)
        pen.ellipse(paw + np.array([12, -6]), 40, 22, col)
    # tail (behind everything)
    ph = J['tail_phase']; amp = J['tail_amp']
    base = T((-345, 548))
    ang = math.radians(192 + amp * math.sin(rig.TAU * ph))
    pts = [base]
    for i in range(6):
        ang += math.radians(8.5 + 0.7 * amp * math.sin(rig.TAU * ph - 0.6 * (i + 1)) / 3)
        pts.append(pts[-1] + 108 * np.array([math.cos(ang), math.sin(ang)]))
    for i in range(6):
        pen.taper(pts[i], pts[i + 1], 78 - 9 * i, 70 - 9 * i if i < 5 else 18, C_BODY if i == 0 else C_FAR if False else (110, 120, 136))
    for name in ('LH', 'LF'):
        leg(name, C_FAR)
    pen.poly([T(p) for p in TORSO], C_BODY)
    # head and neck with nod
    def H(v):
        return T(v) + np.array([0, hd * (0.4 + 0.6 * max(0, (v[0] - 220) / 300))])
    pen.poly([H(p) for p in NECK], C_BODY)
    pen.poly([H(p) for p in [(450, 690), (488, 815), (545, 700)]], C_FAR)       # far ear
    pen.ellipse(H((500, 640)), 95, 75, C_HEAD)
    pen.poly([H(p) for p in [(530, 700), (665, 602), (672, 572), (585, 540), (470, 585)]], C_HEAD)
    pen.poly([H(p) for p in [(505, 690), (552, 805), (590, 688)]], C_HEAD)      # near ear
    pen.disc(H((585, 640)), 12, C_MARK)                                          # eye
    for name in ('RH', 'RF'):
        leg(name, C_NEAR)


def render_sheet(char, kind, frames, layout, path):
    W, Hh, cols, rows = LAYOUTS[layout]
    rects = cells(W, Hh, cols, rows)
    img = Image.new('RGB', (W * SS, Hh * SS), KEY)
    d = ImageDraw.Draw(img)
    meta = []
    for slot, (f, J) in enumerate(frames):
        x0, y0, x1, y1 = rects[slot]
        if char == 'eng':
            ox = (x0 + x1) / 2; oy = y0 + ENG_BASE; s = ENG_H
            pen = Pen(d, ox, oy, s); draw_engineer(pen, J)
            hip_px = [ox + J['hip'][0] * s, oy - J['hip'][1] * s]
            contacts = {}
            for nm in ('near', 'far'):
                if J[nm + '_stance']:
                    hx = min(J[nm + '_heel'][0], J[nm + '_toe'][0]); tx = max(J[nm + '_heel'][0], J[nm + '_toe'][0])
                    contacts[nm] = [ox + hx * s, ox + tx * s]
            extra = {nm + '_ankle': [ox + J[nm + '_ankle'][0] * s, oy - J[nm + '_ankle'][1] * s] for nm in ('near', 'far')}
            clamped = [nm for nm in ('near', 'far') if J[nm + '_clamped']]
        else:
            ox = (x0 + x1) / 2 + WOLF_CX_OFF; oy = y0 + WOLF_BASE; s = WOLF_S
            pen = Pen(d, ox, oy, s); draw_wolf(pen, J)
            hip_px = [ox + J['hip'][0] * s, oy - J['hip'][1] * s]
            contacts = {}
            for nm in ('RH', 'RF', 'LH', 'LF'):
                if J[nm + '_stance']:
                    contacts[nm] = [ox + (J[nm + '_paw'][0] - 28) * s, ox + (J[nm + '_paw'][0] + 52) * s]
            extra = {'shoulder': [ox + J['shoulder'][0] * s, oy - J['shoulder'][1] * s]}
            clamped = [nm for nm in ('RH', 'RF', 'LH', 'LF') if J[nm + '_clamped']]
        meta.append(dict(frame=f, slot=slot, cell=[x0, y0, x1, y1], origin=[ox, oy], scale=s,
                         hip=hip_px, baseline=oy, contacts=contacts, clamped=clamped, **extra))
    img = img.resize((W, Hh), Image.LANCZOS)
    img.save(path)
    return meta


def build():
    os.makedirs(OUT, exist_ok=True)
    allmeta = {}
    jobs = [
        ('eng', 'walk', 12, 'eng-gait', 6),
        ('eng', 'jog', 12, 'eng-gait', 6),
        ('eng', 'idle', 8, 'eng-idle', 8),
        ('wolf', 'walk', 12, 'wolf', 4),
        ('wolf', 'trot', 12, 'wolf', 4),
        ('wolf', 'idle', 8, 'wolf', 4),
    ]
    for char, kind, n, layout, per in jobs:
        poser = rig.eng_pose if char == 'eng' else rig.wolf_pose
        frames = [(f, poser(kind, f, n)) for f in range(n)]
        sheets = []
        for part in range(n // per):
            chunk = frames[part * per:(part + 1) * per]
            name = f'{char}-{kind}-{part + 1}.png'
            meta = render_sheet(char, kind, chunk, layout, os.path.join(OUT, name))
            sheets.append(dict(file=name, frames=meta))
        stride = frames[0][1]['stride']
        allmeta[f'{char}-{kind}'] = dict(char=char, kind=kind, n=n, layout=layout, per=per,
                                          stride_units=stride, sheets=sheets,
                                          scale=ENG_H if char == 'eng' else WOLF_S)
    with open(os.path.join(OUT, 'guides.json'), 'w') as fh:
        json.dump(allmeta, fh, indent=1)
    return allmeta


if __name__ == '__main__':
    m = build()
    for k, v in m.items():
        cl = [(fr['frame'], fr['clamped']) for s in v['sheets'] for fr in s['frames'] if fr['clamped']]
        print(k, 'stride(units)=%.3f' % v['stride_units'], 'clamped:', cl)
