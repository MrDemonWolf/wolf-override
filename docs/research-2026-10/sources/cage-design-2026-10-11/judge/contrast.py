# Measure WOLF's luminance against what is right around him, in real captures,
# using the sprite's own alpha as the mask (canvas_xform from each _log.json).
import json, os, numpy as np
from PIL import Image, ImageFilter
S='[session scratch, not kept]/cage-design'
tex=Image.open(S+'/audit/game-main/apps/game/assets/wolf-side-right-provisional.png').convert('RGBA')
def mask_for(xf, wolf_pos=(115,423), spr_y=-15, flip=False):
    sx, _, _, sy, ox, oy = xf  # canvas xform at base res
    k=1280/960
    scale=0.18325*sx*k
    cx=(wolf_pos[0]*sx+ox)*k; cy=((wolf_pos[1]+spr_y)*sy+oy)*k
    w,h=tex.size
    t=tex.resize((round(w*scale),round(h*scale)), Image.LANCZOS)
    if flip: t=t.transpose(Image.FLIP_LEFT_RIGHT)
    m=Image.new('L',(1280,720),0)
    m.paste(t.split()[3],(round(cx-t.size[0]/2),round(cy-t.size[1]/2)))
    a=np.array(m)>128
    ring=np.array(m.filter(ImageFilter.MaxFilter(15)))>20
    ring=ring & ~ (np.array(m.filter(ImageFilter.MaxFilter(3)))>20)
    return a, ring
def lum(img):
    a=np.asarray(img.convert('RGB')).astype(float)/255
    a=np.where(a<=0.04045,a/12.92,((a+0.055)/1.055)**2.4)
    return 0.2126*a[...,0]+0.7152*a[...,1]+0.0722*a[...,2]
def cr(l1,l2):
    hi,lo=max(l1,l2),min(l1,l2); return (hi+0.05)/(lo+0.05)
runs={'main':S+'/audit/shots','A':S+'/option-a/shots/final','B':S+'/option-b/shots/run6-baked','C':S+'/option-c/shots/design'}
for k,folder in runs.items():
    log=json.load(open(folder+'/_log.json'))
    for e in log:
        f=e.get('file','')
        if f not in ('02-beat1-standby-noui.png','02-beat1-standby.png','04-beat2-wake-settled-noui.png','04-beat2-wake-settled.png'): continue
        p=os.path.join(folder,f.replace('.png','-noui.png') if 'noui' not in f else f)
        if not os.path.exists(p): p=os.path.join(folder,f)
        a,ring=mask_for(e['canvas_xform'])
        L=lum(Image.open(p))
        lw=L[a].mean(); lr=L[ring].mean()
        print(f'{k:5s} {os.path.basename(p):32s} wolf L={lw:.4f} around={lr:.4f} contrast={cr(lw,lr):.2f}  px={a.sum()}')
        break
    # second
    for e in log:
        if e.get('file','').startswith('04-beat2-wake-settled'):
            p=os.path.join(folder,'04-beat2-wake-settled-noui.png')
            a,ring=mask_for(e['canvas_xform']); L=lum(Image.open(p))
            lw=L[a].mean(); lr=L[ring].mean()
            print(f'{k:5s} {"beat2 settled":32s} wolf L={lw:.4f} around={lr:.4f} contrast={cr(lw,lr):.2f}')
            break
