# contact sheet: sheet.py OUT.png W COLS file1 file2 ... (labels from file names)
import sys
from PIL import Image, ImageDraw
out=sys.argv[1]; w=int(sys.argv[2]); cols=int(sys.argv[3]); files=sys.argv[4:]
ims=[Image.open(f).convert('RGB') for f in files]
h=int(ims[0].height*w/ims[0].width)
rows=(len(ims)+cols-1)//cols
sheet=Image.new('RGB',(cols*w,rows*(h+16)),(20,20,20))
d=ImageDraw.Draw(sheet)
for i,(im,f) in enumerate(zip(ims,files)):
    x=(i%cols)*w; y=(i//cols)*(h+16)
    sheet.paste(im.resize((w,h),Image.LANCZOS),(x,y+16))
    d.text((x+4,y+2),f.split('/')[-1],fill=(255,255,0))
sheet.save(out)
