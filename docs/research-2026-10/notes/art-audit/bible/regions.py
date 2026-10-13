# Region sampler for key art B: median hex of pixels in a box passing a Lab gate. stdlib only.
import sys, json, math, os, types
_mp=os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))),'tools','measure.py')
m=types.ModuleType('m'); exec(open(_mp).read().split('def measure')[0], m.__dict__)
exec(open(os.path.join(os.path.dirname(os.path.abspath(__file__)),'palette.py')).read().split('def hx')[0].split('m=types.ModuleType')[1].split('\n',1)[1])
def hx(c): return '#%02x%02x%02x'%tuple(int(round(v)) for v in c)
def med(v): v=sorted(v); return v[len(v)//2]
w,h,bpp,d=m.read_png(sys.argv[1])
R={ # name: (x0,y0,x1,y1, gate)
 'jacket_red_lit':(160,330,320,560, lambda L,C,hh: C>=35 and (hh<50 or hh>350) and L>=30),
 'jacket_red_shadow':(160,330,320,560, lambda L,C,hh: C>=25 and (hh<50 or hh>350) and L<30),
 'wolf_armour_lit':(280,440,580,700, lambda L,C,hh: C<12 and 35<=L<70),
 'wolf_armour_mid':(280,440,580,700, lambda L,C,hh: C<12 and 12<=L<35),
 'wolf_seam_cyan':(280,440,580,700, lambda L,C,hh: C>=25 and 180<=hh<270 and L>=50),
 'char_rim_top':(160,330,580,700, lambda L,C,hh: L>=70),
 'keypad_cyan':(740,420,840,520, lambda L,C,hh: C>=25 and 190<=hh<270),
 'door_light_strip':(600,240,760,300, lambda L,C,hh: L>=60),
 'amber_practical':(400,180,520,420, lambda L,C,hh: C>=30 and 30<=hh<90),
 'amber_anywhere':(0,0,1000,941, lambda L,C,hh: C>=40 and 45<=hh<90 and L>=40),
 'red_practical':(0,0,1000,941, lambda L,C,hh: C>=45 and (hh<45) and L>=35 and not False),
 'ceiling_lamp':(150,60,400,120, lambda L,C,hh: L>=80),
 'lamp_shaft':(150,120,400,600, lambda L,C,hh: 30<=L<70 and 200<=hh<290),
 'floor_reflection_hi':(0,650,1000,941, lambda L,C,hh: L>=45),
 'floor_wet_mid':(0,650,1000,941, lambda L,C,hh: 8<=L<45),
 'floor_dark':(0,650,1000,941, lambda L,C,hh: L<8),
 'negative_space_right':(1000,0,1672,941, lambda L,C,hh: True),
 'wall_mid_left':(450,100,900,600, lambda L,C,hh: True),
}
out={}
for k,(x0,y0,x1,y1,g) in R.items():
    s=[]
    for y in range(y0,min(y1,h),2):
        for x in range(x0,min(x1,w),2):
            i=(y*w+x)*bpp; r,gg,b=d[i],d[i+1],d[i+2]; L,A,Bb=lab(r,gg,b)
            C=math.hypot(A,Bb); hh=(math.degrees(math.atan2(Bb,A))+360)%360
            if g(L,C,hh): s.append((r,gg,b,L,C,hh))
    if not s: out[k]=None; continue
    out[k]={'hex':hx((med([q[0] for q in s]),med([q[1] for q in s]),med([q[2] for q in s]))),'n':len(s),'L':round(med([q[3] for q in s]),1),'C':round(med([q[4] for q in s]),1),'h':round(med([q[5] for q in s])),'L_p95':round(sorted(q[3] for q in s)[int(len(s)*.95)],1)}
print(json.dumps(out,indent=0))
