import zlib, struct, sys, json, os, math, colorsys
def read_png(p):
    b=open(p,'rb').read(); assert b[:8]==b'\x89PNG\r\n\x1a\n'
    i=8; idat=b''; 
    while i<len(b):
        n,=struct.unpack('>I',b[i:i+4]); t=b[i+4:i+8]; d=b[i+8:i+8+n]; i+=12+n
        if t==b'IHDR': w,h,bd,ct,_,_,il=struct.unpack('>IIBBBBB',d)
        elif t==b'IDAT': idat+=d
    assert bd==8 and il==0 and ct in (2,6), (bd,ct,il)
    bpp=4 if ct==6 else 3; stride=w*bpp; raw=zlib.decompress(idat)
    out=bytearray(h*stride); prev=bytearray(stride)
    for y in range(h):
        f=raw[y*(stride+1)]; line=bytearray(raw[y*(stride+1)+1:(y+1)*(stride+1)])
        if f==1:
            for x in range(bpp,stride): line[x]=(line[x]+line[x-bpp])&255
        elif f==2:
            for x in range(stride): line[x]=(line[x]+prev[x])&255
        elif f==3:
            for x in range(stride): line[x]=(line[x]+(((line[x-bpp] if x>=bpp else 0)+prev[x])>>1))&255
        elif f==4:
            for x in range(stride):
                a=line[x-bpp] if x>=bpp else 0; c=prev[x-bpp] if x>=bpp else 0; bb=prev[x]
                pp=a+bb-c; pa=abs(pp-a); pb=abs(pp-bb); pc=abs(pp-c)
                pr=a if pa<=pb and pa<=pc else (bb if pb<=pc else c)
                line[x]=(line[x]+pr)&255
        out[y*stride:(y+1)*stride]=line; prev=line
    return w,h,bpp,out
def lin(c):
    c/=255; return c/12.92 if c<=0.04045 else ((c+0.055)/1.055)**2.4
LUT=[lin(i) for i in range(256)]
def Lstar(Y): return 116*(Y**(1/3))-16 if Y>0.008856 else 903.3*Y
def measure(p, step=2, band=None):
    w,h,bpp,px=read_png(p); Ls=[]; S=[]; grads=[]; opaque=0; tot=0
    y0,y1=(0,h) if band is None else band
    for y in range(y0,y1-step,step):
        row=y*w*bpp
        for x in range(0,w-step,step):
            i=row+x*bpp; tot+=1
            a=px[i+3] if bpp==4 else 255
            if a<128: continue
            opaque+=1
            r,g,b=px[i],px[i+1],px[i+2]
            Y=0.2126*LUT[r]+0.7152*LUT[g]+0.0722*LUT[b]; L=Lstar(Y); Ls.append(L)
            mx=max(r,g,b); mn=min(r,g,b); S.append(0 if mx==0 else (mx-mn)/mx)
            j=i+step*bpp; k=i+step*w*bpp
            if (bpp==3 or (px[j+3]>=128 and px[k+3]>=128)):
                L2=Lstar(0.2126*LUT[px[j]]+0.7152*LUT[px[j+1]]+0.0722*LUT[px[j+2]])
                L3=Lstar(0.2126*LUT[px[k]]+0.7152*LUT[px[k+1]]+0.0722*LUT[px[k+2]])
                grads.append(abs(L2-L)+abs(L3-L))
    Ls.sort(); n=len(Ls)
    q=lambda f: round(Ls[min(n-1,int(f*n))],1) if n else None
    return dict(w=w,h=h,opaque_frac=round(opaque/max(tot,1),3),L_mean=round(sum(Ls)/n,1) if n else None,
        L_p05=q(.05),L_p50=q(.5),L_p95=q(.95),L_spread_p05_p95=round(q(.95)-q(.05),1) if n else None,
        sat_mean=round(sum(S)/max(len(S),1),3),detail_grad_mean=round(sum(grads)/max(len(grads),1),2),
        vram_rgba8_MB=round(w*h*4/2**20,2))
root=sys.argv[1]; res={}
for rel in sys.argv[2:]:
    res[rel]=measure(os.path.join(root,rel), step=2 if os.path.getsize(os.path.join(root,rel))>600000 else 1)
    print(rel,res[rel],flush=True)
json.dump(res,open(sys.argv[0].replace('tools/measure.py','evidence/measure.json'),'w'),indent=1)
