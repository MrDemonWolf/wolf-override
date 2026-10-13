# Palette sampler for the art bible. stdlib only. usage: python3 -I palette.py <png> [step] [label]
import sys, json, math, random, colorsys, importlib.util
import os, types
_mp=os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))),'tools','measure.py')
m=types.ModuleType('m'); exec(open(_mp).read().split('def measure')[0], m.__dict__)
def lab(r,g,b):
    R,G,B=m.LUT[r],m.LUT[g],m.LUT[b]
    X=(0.4124*R+0.3576*G+0.1805*B)/0.95047; Y=0.2126*R+0.7152*G+0.0722*B; Z=(0.0193*R+0.1192*G+0.9505*B)/1.08883
    f=lambda t: t**(1/3) if t>0.008856 else 7.787*t+16/116
    return 116*f(Y)-16, 500*(f(X)-f(Y)), 200*(f(Y)-f(Z))
def hx(c): return '#%02x%02x%02x'%tuple(int(round(v)) for v in c)
def med(v): v=sorted(v); return v[len(v)//2]
p=sys.argv[1]; step=int(sys.argv[2]) if len(sys.argv)>2 else 3
w,h,bpp,d=m.read_png(p)
px=[]
for y in range(0,h,step):
    for x in range(0,w,step):
        i=(y*w+x)*bpp; a=d[i+3] if bpp==4 else 255
        if a<250: continue
        r,g,b=d[i],d[i+1],d[i+2]; L,A,Bb=lab(r,g,b)
        hh=(math.degrees(math.atan2(Bb,A))+360)%360; C=math.hypot(A,Bb)
        px.append((x,y,r,g,b,L,C,hh))
out={'file':p,'size':[w,h],'n':len(px)}
def group(name,cond):
    s=[q for q in px if cond(q)]
    if not s: out[name]=None; return
    mr=(med([q[2] for q in s]),med([q[3] for q in s]),med([q[4] for q in s]))
    out[name]={'hex':hx(mr),'share_pct':round(100*len(s)/len(px),2),'L_med':round(med([q[5] for q in s]),1),'C_med':round(med([q[6] for q in s]),1),'h_med':round(med([q[7] for q in s]))}
# value bands (all hues)
for lo,hi in [(0,3),(3,8),(8,15),(15,25),(25,40),(40,60),(60,101)]:
    group('L%d-%d'%(lo,hi), lambda q,lo=lo,hi=hi: lo<=q[5]<hi)
# accents by hue (Lab hue angle), chroma gate
group('accent_red',   lambda q: q[6]>=25 and (q[7]>=10 and q[7]<45))
group('accent_amber', lambda q: q[6]>=20 and 45<=q[7]<95)
group('accent_green', lambda q: q[6]>=20 and 120<=q[7]<180)
group('cyan_light',   lambda q: q[6]>=15 and 190<=q[7]<260 and q[5]>=45)
group('cold_mid',     lambda q: 190<=q[7]<290 and 10<=q[5]<40)
group('cold_shadow',  lambda q: 3<=q[5]<10)
group('highlight_top',lambda q: q[5]>=75)
lv=sorted(q[5] for q in px)
out['L_pct']={k:round(lv[int(len(lv)*k/100) if k<100 else -1],1) for k in (1,5,25,50,75,95,99)}
out['C_med_all']=round(med([q[6] for q in px]),1)
# per vertical band if requested
if len(sys.argv)>3 and sys.argv[3]=='bands':
    out['rows']={}
    for a,b_ in [(0,.25),(.25,.5),(.5,.75),(.75,1)]:
        s=[q[5] for q in px if a*h<=q[1]<b_*h]; out['rows']['%g-%g'%(a,b_)]=round(med(s),1) if s else None
print(json.dumps(out))
