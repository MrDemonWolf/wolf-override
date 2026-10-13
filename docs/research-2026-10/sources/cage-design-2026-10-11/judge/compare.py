import sys, os
from PIL import Image, ImageDraw, ImageFont
S = '[session scratch, not kept]/cage-design'
rows = {
 'main': (S+'/audit/shots', ['02-beat1-standby-noui','04-beat2-wake-settled-noui','06-beat3-latch-f006','10-beat3-latch-f030','18-beat3-settled-noui','23-beat6-only-open-route-noui']),
 'A':    (S+'/option-a/shots/final', ['02-beat1-standby-noui','04-beat2-wake-settled-noui','09-beat3-f006','13-beat3-f030','24-beat3-f150-noui','27-beat6-only-open-route-noui']),
 'B':    (S+'/option-b/shots/run6-baked', ['02-beat1-standby-noui','04-beat2-wake-settled-noui','08-beat3-latch-f008-noui','13-beat3-latch-f030','22-beat3-settled-noui','25-beat6-only-open-route-noui']),
 'C':    (S+'/option-c/shots/design', ['02-beat1-standby-noui','04-beat2-wake-settled-noui','07-beat3-latch-f009-noui','11-beat3-latch-f030','18-beat3-settled-noui','23-beat6-only-open-route-noui']),
}
box = (0, 230, 700, 600)
W = box[2]-box[0]; H = box[3]-box[1]
sc = 0.5
cw, ch = int(W*sc), int(H*sc)
font = ImageFont.load_default(size=18)
out = Image.new('RGB', (60+cw*6, 30+ch*4), (235,235,230))
d = ImageDraw.Draw(out)
cols = ['beat1 standby','beat2 wake','beat3 ~0.1s','beat3 0.5s','beat3 settled','beat6']
for j,c in enumerate(cols): d.text((60+j*cw+4, 6), c, fill=(0,0,0), font=font)
for i,(k,(folder,names)) in enumerate(rows.items()):
    d.text((10, 30+i*ch+ch//2), k, fill=(0,0,0), font=font)
    for j,n in enumerate(names):
        p = os.path.join(folder, n+'.png')
        if not os.path.exists(p):
            d.text((60+j*cw+4, 30+i*ch+10), 'missing '+n, fill=(200,0,0), font=font); continue
        im = Image.open(p).convert('RGB').crop(box).resize((cw,ch), Image.LANCZOS)
        out.paste(im, (60+j*cw, 30+i*ch))
out.save(S+'/judge/compare.png')
print(out.size)
