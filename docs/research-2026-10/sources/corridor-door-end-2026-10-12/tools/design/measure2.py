"""Prints the v2 design's values per part (sRGB luma 0-255: p10 / median / p90)."""
import sys
import numpy as np
from PIL import Image
D = sys.argv[1]
def L(rgb): return rgb[...,0]*0.2126+rgb[...,1]*0.7152+rgb[...,2]*0.0722
for lay,parts in (('wall',['face_upper','face_far_column','reveal_far','threshold','stand_column','stand_gearbox','drive_guard','door_light_body','jb_box']),('curtain',['curtain_face']),('front',['pier_face','pier_end','pb_box']),('frame',['hood_front','hood_top','guide_far','operator_body']),('wheel',['wheel_rim','wheel_spokes'])):
    im=np.asarray(Image.open('%s/design-%s.png'%(D,lay)).convert('RGBA')).astype(float)
    for p in parts:
        m=np.asarray(Image.open('%s/masks/%s--%s.png'%(D,lay,p))).astype(float)/255>0.99
        l=L(im[...,:3])[m]
        print('%-8s %-18s %5.1f %5.1f %5.1f'%(lay,p,np.percentile(l,10),np.median(l),np.percentile(l,90)))
im=np.asarray(Image.open('%s/design-wall.png'%D).convert('RGBA')).astype(float)
m=np.asarray(Image.open('%s/masks/wall--face_upper.png'%D)).astype(float)/255>0.99
l=L(im[...,:3])
for y in range(0,640,60):
    row=m[y]
    if row.any(): print('upper y',150+y/4, np.round(l[y][row][::40],0))
