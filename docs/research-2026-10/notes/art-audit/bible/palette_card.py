# Writes palette-card.png: the colour-only reference attached to every Codex call. stdlib only.
import zlib, struct, sys
ROWS = [
 ['#000307','#07101a','#121f2c','#1d3042','#2f4d69','#4175a0','#82c3e6','#ade4fb','#e3f6fe'],   # value ramp, key art B
 ['#5f0e17','#a01e29','#ad252d','#ca452f','#82510e','#c89876','#e0936e','#17632f','#56dc69'],   # accents
 ['#292f37','#656a72','#c3c5d7','#4f8ab8','#2091ca','#30d0fc','#385d85','#1e2e3c','#73a9cc'],   # materials and light
]
S = 160; G = 8; W = len(ROWS[0])*S + (len(ROWS[0])+1)*G; H = len(ROWS)*S + (len(ROWS)+1)*G
bg = (0x10, 0x14, 0x18)
px = [[bg]*W for _ in range(H)]
for r, row in enumerate(ROWS):
    for c, hx in enumerate(row):
        col = tuple(int(hx[i:i+2], 16) for i in (1, 3, 5))
        y0 = G + r*(S+G); x0 = G + c*(S+G)
        for y in range(y0, y0+S):
            for x in range(x0, x0+S): px[y][x] = col
raw = b''.join(b'\x00' + bytes(v for p in line for v in p) for line in px)
def chunk(t, d): return struct.pack('>I', len(d)) + t + d + struct.pack('>I', zlib.crc32(t+d) & 0xffffffff)
png = b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', struct.pack('>IIBBBBB', W, H, 8, 2, 0, 0, 0)) + chunk(b'IDAT', zlib.compress(raw, 9)) + chunk(b'IEND', b'')
open(sys.argv[1], 'wb').write(png); print(W, H)
