"""Build the crank pose guide sheet for Codex (edit target), from the approved idle frame.

Sheet 1536x1024, flat #FF00FF, three cells 512 wide, every figure at K = 2.9 sheet px per cell px
with its pivot (cell x 128) at the cell's centre and its baseline (cell row 311) on sheet row
BASE_Y. Cell 1 is the approved eng-idle frame_00, unchanged (the anchor). Cells 2 and 3 are the
same painting re-posed as a cut-out:
  - legs and boots: the idle painting's own pixels, unchanged (planted feet, no slide);
  - torso and head: the idle painting rotated forward about the hip (lean A 7 deg, B 3 deg);
  - the idle's hanging near arm is cut out; where it covered the body, flat jacket red (torso),
    belt black and trouser charcoal fill the hole;
  - the new near arm is a LIGHT GREY mannequin (shoulder -> elbow -> closed fist on the rim point);
  - the far arm is a DARK GREY mannequin behind the body, its open hand braced flat on the wall
    plate above the wheel (the same point in both frames).
The wheel is not drawn (it is in the game, behind the engineer); its rim is marked only in the
separate check image guide-check.png, never in what Codex sees.

usage: build_guide.py OUTDIR
"""
import json, math, os, sys
import numpy as np
from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(__file__))
import geometry as GEO  # noqa: E402

IDLE = '~/Developer/mrdemonwolf/wolf-override/docs/research-2026-10/sources/walk-final-2026-10-11/engineer/eng-idle/frame_00.png'
K = 2.9
SHEET_W, SHEET_H = 1536, 1024
CELL_SW = 512
TOP = 60
BASE_Y = TOP + GEO.BASE_ROW * K  # sheet row of the baseline
MAGENTA = (255, 0, 255)

# idle landmarks (cell px), read off idle-upper-5x.png
HIP = (130.0, 170.0)          # rotation centre of the lean
NEAR_SHOULDER = (129.0, 97.0)
FAR_SHOULDER = (134.0, 99.0)
UPPER_LEN, FORE_LEN = 49.0, 40.0          # near arm: shoulder -> elbow -> fist centre
FAR_UPPER_LEN, FAR_FORE_LEN = 28.0, 26.0  # far arm: foreshortened, it reaches back into depth to the wall
WAIST_Y = 166.0               # torso above, legs below
NECK = (140.0, 84.0)          # the head nods forward about this point (head = above NECK_Y)
NECK_Y = 84.0
# the idle's hanging near arm (sleeve with its pocket, cuff, wrist and glove), cell px
NEAR_ARM_POLY = [(104, 90), (113, 86), (126, 86), (134, 94), (137, 112), (137, 150), (135, 160),
                 (143, 168), (145, 186), (143, 203), (130, 206), (119, 203), (116, 186), (114, 168),
                 (108, 160), (100, 150), (99, 120)]
# the idle's far glove, hanging at the front of the thigh (it goes up to the wall in the crank)
FAR_GLOVE_POLY = [(149, 166), (166, 166), (168, 190), (165, 208), (149, 208)]
# far hand braced on the bypass backplate (its top edge is world y 384 = cell y 91, its left edge
# world x 685 = cell x 171): palm flat on the plate above-left of the wheel, in both frames
FAR_HAND = (179.0, 110.0)

JACKET = (102, 37, 43)
BELT = (30, 32, 36)
TROUSER = (59, 66, 70)
NEAR_GREY = (196, 200, 206)
FAR_GREY = (98, 102, 110)

POSES = {
    'crank-a': dict(lean=9.0, nod=6.0, grip=GEO.GRIP_A, label='grip low at 8 o\'clock, about to push'),
    'crank-b': dict(lean=4.0, nod=3.0, grip=GEO.GRIP_B, label='pushed up to half past 9'),
}


def rot(p, c, deg):
    """Rotate p about c by deg, clockwise on screen (top moves right for a lean forward)."""
    a = math.radians(deg)
    x, y = p[0] - c[0], p[1] - c[1]
    return (c[0] + x * math.cos(a) - y * math.sin(a), c[1] + x * math.sin(a) + y * math.cos(a))


def ik(sh, tgt, l1, l2, elbow_back=True):
    dx, dy = tgt[0] - sh[0], tgt[1] - sh[1]
    d = math.hypot(dx, dy)
    d_c = min(d, l1 + l2 - 0.5)
    ca = (l1 * l1 + d_c * d_c - l2 * l2) / (2 * l1 * d_c)
    a = math.acos(max(-1.0, min(1.0, ca)))
    base = math.atan2(dy, dx)
    sols = [(sh[0] + l1 * math.cos(base + s * a), sh[1] + l1 * math.sin(base + s * a)) for s in (1, -1)]
    # elbow_back: the elbow points back (smaller x) / down, as a real arm reaching forward does
    sols.sort(key=lambda e: (e[0] - e[1] * 0.3) if elbow_back else -e[1])
    return sols[0], d


def premul_resize(img, k):
    a = np.asarray(img).astype(np.float32) / 255.0
    W, H = int(round(img.width * k)), int(round(img.height * k))
    pm = a[..., :3] * a[..., 3:4]
    ch = [np.asarray(Image.fromarray(pm[..., c], 'F').resize((W, H), Image.LANCZOS)) for c in range(3)]
    A = np.clip(np.asarray(Image.fromarray(a[..., 3], 'F').resize((W, H), Image.LANCZOS)), 0, 1)
    rgb = np.stack(ch, -1) / np.maximum(A[..., None], 1e-4)
    out = np.dstack([np.clip(rgb, 0, 1) * 255, A * 255]).round().astype(np.uint8)
    out[A < 0.02] = 0
    return Image.fromarray(out, 'RGBA')


def poly_mask(size, pts, k):
    m = Image.new('L', size, 0)
    ImageDraw.Draw(m).polygon([(x * k, y * k) for x, y in pts], fill=255)
    return m


def capsule(draw, p, q, w, fill, k):
    p = (p[0] * k, p[1] * k); q = (q[0] * k, q[1] * k); r = w * k / 2
    draw.line([p, q], fill=fill, width=int(round(w * k)))
    for c in (p, q):
        draw.ellipse([c[0] - r, c[1] - r, c[0] + r, c[1] + r], fill=fill)


def build_pose(big, pose):
    W, H = big.size
    lean = pose['lean']
    arm = poly_mask(big.size, NEAR_ARM_POLY, K)
    arm.paste(255, mask=poly_mask(big.size, FAR_GLOVE_POLY, K))
    alpha = big.getchannel('A')
    body = Image.new('RGBA', big.size, (0, 0, 0, 0))
    # fill under the cut-out arm, inside the idle silhouette
    yy = np.arange(H)[:, None] / K
    xx = np.arange(W)[None, :] / K
    # the body's own back edge behind the arm: the jacket at x >= 108, the thigh at x >= 119
    inside = np.where(yy < WAIST_Y, xx >= 108, (xx >= 119) & (xx <= 158))
    hole = Image.fromarray((np.asarray(arm) > 127) & (np.asarray(alpha) > 127) & inside).convert('L')
    fill = np.zeros((H, W, 4), np.uint8)
    fill[..., :3] = np.where(yy[..., None] < 150, JACKET, np.where(yy[..., None] < WAIST_Y, BELT, TROUSER))
    fill[..., 3] = np.asarray(hole)
    filled = big.copy()
    # cut the arm away, then paste the flat fill where it covered the body
    fa = np.asarray(filled).copy(); fa[np.asarray(arm) > 127] = 0
    filled = Image.fromarray(fa, 'RGBA')
    filled.alpha_composite(Image.fromarray(fill, 'RGBA'))
    # split at the waist; rotate the torso about the hip
    fa = np.asarray(filled)
    upper = fa.copy(); upper[int((WAIST_Y + 4) * K):] = 0  # 4 px overlap so no seam opens
    lower = fa.copy(); lower[:int(WAIST_Y * K)] = 0
    # the head nods toward the wheel about the neck, then the whole torso leans about the hip
    head = upper.copy(); head[int((NECK_Y + 5) * K):] = 0  # 5 px overlap so no seam opens
    chest = upper.copy(); chest[:int(NECK_Y * K)] = 0
    tors = Image.fromarray(chest, 'RGBA')
    tors.alpha_composite(Image.fromarray(head, 'RGBA'))  # unrotated head under the nodded one fills the nape
    tors.alpha_composite(Image.fromarray(head, 'RGBA').rotate(-pose['nod'], resample=Image.BICUBIC, center=(NECK[0] * K, NECK[1] * K)))
    up_img = tors.rotate(-lean, resample=Image.BICUBIC, center=(HIP[0] * K, HIP[1] * K))
    body.alpha_composite(Image.fromarray(lower, 'RGBA'))
    body.alpha_composite(up_img)
    # arms
    out = Image.new('RGBA', big.size, (0, 0, 0, 0))
    far = Image.new('RGBA', big.size, (0, 0, 0, 0)); fd = ImageDraw.Draw(far)
    fsh = rot(FAR_SHOULDER, HIP, lean)
    felb, fdist = ik(fsh, FAR_HAND, FAR_UPPER_LEN, FAR_FORE_LEN, elbow_back=True)
    capsule(fd, fsh, felb, 15, FAR_GREY + (255,), K)
    capsule(fd, felb, FAR_HAND, 12, FAR_GREY + (255,), K)
    # open hand, palm flat on the wall: a rounded block, fingers pointing up and forward
    hx, hy = FAR_HAND
    fd.rounded_rectangle([(hx - 6) * K, (hy - 11) * K, (hx + 7) * K, (hy + 5) * K], radius=4 * K, fill=FAR_GREY + (255,))
    out.alpha_composite(far)
    out.alpha_composite(body)
    near = Image.new('RGBA', big.size, (0, 0, 0, 0)); nd = ImageDraw.Draw(near)
    nsh = rot(NEAR_SHOULDER, HIP, lean)
    grip = pose['grip']
    elb, dist = ik(nsh, grip, UPPER_LEN, FORE_LEN)
    capsule(nd, nsh, elb, 19, NEAR_GREY + (255,), K)
    capsule(nd, elb, grip, 15, NEAR_GREY + (255,), K)
    r = 9.0
    nd.ellipse([(grip[0] - r) * K, (grip[1] - r) * K, (grip[0] + r) * K, (grip[1] + r) * K], fill=NEAR_GREY + (255,))
    out.alpha_composite(near)
    info = dict(lean_deg=lean, near_shoulder=[round(v, 1) for v in nsh], near_elbow=[round(v, 1) for v in elb],
                grip=[round(v, 1) for v in grip], shoulder_to_grip=round(dist, 1), arm_len=UPPER_LEN + FORE_LEN,
                far_shoulder=[round(v, 1) for v in fsh], far_elbow=[round(v, 1) for v in felb], far_hand=list(FAR_HAND),
                far_reach=round(fdist, 1))
    return out, info


def main(outdir):
    os.makedirs(outdir, exist_ok=True)
    idle = Image.open(IDLE).convert('RGBA')
    big = premul_resize(idle, K)
    sheet = Image.new('RGBA', (SHEET_W, SHEET_H), MAGENTA + (255,))
    check = Image.new('RGBA', (SHEET_W, SHEET_H), MAGENTA + (255,))
    meta = dict(K=K, sheet=[SHEET_W, SHEET_H], base_y=BASE_Y, top=TOP, cells=[], hub_cell=list(GEO.HUB), rim_r_cell=GEO.RIM_R)
    figs = [('anchor', big, None)]
    for name, pose in POSES.items():
        img, info = build_pose(big, pose)
        figs.append((name, img, info))
    for i, (name, img, info) in enumerate(figs):
        ox = CELL_SW * i + CELL_SW / 2 - GEO.PIVOT_X * K
        oy = TOP
        pos = (int(round(ox)), int(round(oy)))
        sheet.alpha_composite(img, pos)
        check.alpha_composite(img, pos)
        d = ImageDraw.Draw(check)
        if name != 'anchor':
            hx, hy = pos[0] + GEO.HUB[0] * K, pos[1] + GEO.HUB[1] * K
            rr = GEO.RIM_R * K
            d.ellipse([hx - rr, hy - rr, hx + rr, hy + rr], outline=(0, 200, 0, 255), width=3)
            gx, gy = pos[0] + info['grip'][0] * K, pos[1] + info['grip'][1] * K
            d.ellipse([gx - 6, gy - 6, gx + 6, gy + 6], outline=(255, 140, 0, 255), width=3)
        d.line([(CELL_SW * i, BASE_Y), (CELL_SW * (i + 1), BASE_Y)], fill=(0, 200, 255, 255), width=1)
        meta['cells'].append(dict(name=name, cell_box=[CELL_SW * i, 0, CELL_SW * (i + 1), SHEET_H], paste=list(pos),
                                  pivot_sheet=[CELL_SW * i + CELL_SW / 2, BASE_Y], info=info))
    sheet.convert('RGB').save(os.path.join(outdir, 'crank-guide.png'))
    check.convert('RGB').save(os.path.join(outdir, 'guide-check.png'))
    # the anchor's alpha alone, for the scale fit after painting
    an = Image.new('L', (SHEET_W, SHEET_H), 0)
    an.paste(big.getchannel('A'), meta['cells'][0]['paste'])
    an.save(os.path.join(outdir, 'anchor-alpha.png'))
    json.dump(meta, open(os.path.join(outdir, 'guide.json'), 'w'), indent=1)
    for c in meta['cells']:
        print(c['name'], c['info'])


if __name__ == '__main__':
    main(sys.argv[1])
