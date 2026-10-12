import sys, os, numpy as np
from PIL import Image
sys.path.insert(0, 'tools')
import rig
from register import feat, ncc_track, eng_cell, wolf_cell
row = sys.argv[1]; char = row.split('-')[0]; kind = row.split('-')[1]
import json
n = json.load(open('guides/guides.json'))[row]['n']
fr = [np.asarray(Image.open('frames/%s/frame_%02d.png' % (row, i))) for i in range(n)]
up = [np.asarray(Image.fromarray(f).resize((f.shape[1]*2, f.shape[0]*2), Image.LANCZOS)) for f in fr]
ft = [feat(u) for u in up]
def pts(i):
    if char == 'eng':
        J = rig.eng_pose(kind, i, n); hip = eng_cell(J['hip']); hd = eng_cell(J['head']); sh = eng_cell(J['shoulder'])
        return {'head': (hd, (50, 50)), 'back': (hip + (sh - hip) * 0.45 + [-10, 0], (22, 50)), 'belt': (hip + [0, -10], (56, 22)),
                'torso': (hip + (sh - hip) * 0.5, (52, 70))}
    J = rig.wolf_pose(kind, i, n); T = J['T']; hd = J.get('head_dy', 0.0); s = 460/1550
    return {'head': (wolf_cell(T((520, 630)) + np.array([0, hd])), (150*s, 130*s)), 'withers': (wolf_cell(T((230, 560))), (170*s, 110*s)),
            'flank': (wolf_cell(T((10, 520))), (190*s, 110*s)), 'croup': (wolf_cell(T((-210, 550))), (150*s, 100*s))}
names = list(pts(0).keys())
steps = {nm: [] for nm in names}; scores = {nm: [] for nm in names}
for i in range(n):
    j = (i + 1) % n
    Pi, Pj = pts(i), pts(j)
    for nm in names:
        off, sc = ncc_track(ft[i], ft[j], Pi[nm][0]*2, Pj[nm][0]*2, (Pi[nm][1][0]*2, Pi[nm][1][1]*2), R=24)
        steps[nm].append(off/2); scores[nm].append(sc)
for nm in names:
    st = np.array(steps[nm]); clos = st.sum(0)
    pos = np.cumsum(np.vstack([[0, 0], st[:-1] - clos/n]), 0)  # residual position vs designed, loop-closed
    pos -= pos.mean(0)
    print('%-8s closure=(%.1f,%.1f) minscore=%.2f' % (nm, clos[0], clos[1], min(scores[nm])))
    print('   x:', ' '.join('%5.1f' % v for v in pos[:, 0]))
    print('   y:', ' '.join('%5.1f' % v for v in pos[:, 1]))
