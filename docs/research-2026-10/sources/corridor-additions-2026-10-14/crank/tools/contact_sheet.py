"""Contact sheet: the delivered crank frames beside the approved idle and walk frames, one baseline.

Reads (read only): docs/research-2026-10/sources/walk-final-2026-10-11/engineer/eng-idle/frame_00.png,
eng-walk/frame_00..; deliver/sprites/eng-crank/frame_00.png (A), frame_01.png (B).
Writes deliver/eng-crank-contact.png: every cell is the 256x320 source cell at 1x, on a mid-grey
backdrop, a cyan line under row 313 (the lowest opaque row of the idle's feet) and a magenta tick at
pivot x 128, so feet, scale and pivot can be compared by eye.
"""
import glob, os, sys
from PIL import Image, ImageDraw

REPO = '~/Developer/mrdemonwolf/wolf-override'
SRC = REPO + '/docs/research-2026-10/sources/walk-final-2026-10-11/engineer'
CRANK = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))
walk = sorted(glob.glob(SRC + '/eng-walk/frame_*.png'))
cells = [('idle 00', SRC + '/eng-idle/frame_00.png')]
cells += [('walk %s' % os.path.basename(p)[6:8], p) for p in walk[::3]]
cells += [('CRANK A (frame_00)', CRANK + '/deliver/sprites/eng-crank/frame_00.png'),
          ('CRANK B (frame_01)', CRANK + '/deliver/sprites/eng-crank/frame_01.png')]
CW, CH, LAB = 256, 320, 22
out = Image.new('RGBA', (CW * len(cells), CH + LAB), (58, 62, 68, 255))
d = ImageDraw.Draw(out)
for i, (label, path) in enumerate(cells):
    im = Image.open(path).convert('RGBA')
    assert im.size == (CW, CH), (path, im.size)
    x = i * CW
    if label.startswith('CRANK'):
        d.rectangle((x, LAB, x + CW - 1, LAB + CH - 1), fill=(48, 56, 66, 255))
    out.alpha_composite(im, (x, LAB))
    d.line((x, LAB + 314, x + CW - 1, LAB + 314), fill=(0, 200, 230, 255))
    d.line((x + 128, LAB + 314, x + 128, LAB + 319), fill=(230, 0, 200, 255))
    d.line((x + CW - 1, 0, x + CW - 1, LAB + CH), fill=(20, 20, 20, 255))
    d.text((x + 6, 5), label, fill=(235, 235, 235, 255))
dst = os.path.join(CRANK, 'deliver', 'eng-crank-contact.png')
out.save(dst)
print(dst, out.size, [c[0] for c in cells])
