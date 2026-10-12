# Builds the pick sheet: one row per option (3 beat frames from main's real opening plus the
# option's own front elevation), a plain caption per row, the recommended row marked.
# Inputs are the options' own captures and drawings; nothing is generated.
from PIL import Image, ImageDraw, ImageFont

S = '/private/tmp/claude-501/-Users-nathanialhenniges-Developer-mrdemonwolf-wolf-override/eb713cd4-8931-48d7-8c83-5b0b0d1e9cf3/scratchpad/cage-design'
FB = '/System/Library/Fonts/Supplemental/Arial Bold.ttf'
FR = '/System/Library/Fonts/Supplemental/Arial.ttf'
def font(p, s): return ImageFont.truetype(p, s)

ROWS = [
    dict(key='A', name='Option A: secure barred cage',
         how="Today's barred look, rebuilt properly: plate back and roof, one barred gate on a track, hook-bolt lock on a plate outside. The keeper tears off; after a 0.15 s hold the gate rolls aside.",
         rank='Rank 3   5.5 / 10', rec=False,
         frames=[(S+'/option-a/shots/r2/02-beat1-standby.png', None, '1  Standby (lock green, dock amber)'),
                 (S+'/option-a/shots/r2/08-beat3-f005.png', None, '2  Latch fails (inside the 0.15 s hold)'),
                 (S+'/option-a/shots/r2/19-beat3-f064.png', None, '3  Steps out (after the slide)')],
         elev=(S+'/option-a/construction-drawing.png', (120, 276, 1690, 1000))),
    dict(key='B', name='Option B: sealed armoured cell',
         how='A closed steel box with two armoured glass panels and a sealed sliding door. The lock bolt holds, the catch on the door tears out, the seal tears and the door runs aside.',
         rank='Rank 2   6.5 / 10', rec=False,
         frames=[(S+'/option-b/render/B1-standby.png', (0, 0, 1280, 720), '1  Standby'),
                 (S+'/option-b/render/B3a-latch-fails.png', (0, 0, 1280, 720), '2  Latch fails (0.13 s)'),
                 (S+'/option-b/render/B3b-steps-out.png', (0, 0, 1280, 720), '3  Steps out (1.0 s)')],
         elev=(S+'/option-b/render/construction.png', (40, 150, 1240, 1068))),
    dict(key='C', name='Option C: standby dock in a guarded bay',
         how='WOLF is parked on a robot stand with a charging cable on his back, behind four sliding mesh panels. He wakes, the lock on the pilaster tears off, the cable lets go, the panels slide aside.',
         rank='Rank 1   7.5 / 10', rec=True,
         frames=[(S+'/option-c/shots/design-r2/02-beat1-standby.png', None, '1  Standby'),
                 (S+'/option-c/shots/design-r2/07-beat3-latch-f009.png', None, '2  Latch fails (0.15 s)'),
                 (S+'/option-c/shots/design-r2/13-beat3-latch-f048.png', None, '3  Steps out (0.8 s)')],
         elev=(S+'/option-c/construction-drawing.png', (59, 230, 1867, 1168))),
]

W = 2520
M = 40
FW, FH = 560, 315          # beat frame size on the sheet
BEAT_CROP = (0, 196, 752, 619)  # 1280x720 capture: the unit, WOLF and the Director (16:9)
GAP = 16
CAP_H = 128
LAB_H = 38
ROW_PAD = 26
ROW_H = CAP_H + FH + LAB_H + ROW_PAD * 2
HEAD_H = 190
FOOT_H = 70
H = HEAD_H + ROW_H * len(ROWS) + GAP * (len(ROWS) - 1) + FOOT_H

BG = (236, 235, 230)
INK = (24, 26, 30)
GREY = (92, 96, 104)
REC = (22, 128, 74)
EDGE = (190, 190, 184)

sheet = Image.new('RGB', (W, H), BG)
d = ImageDraw.Draw(sheet)

d.text((M, 30), "WOLF's containment: three designs to pick from (revision 2, judge's fixes applied)", font=font(FB, 54), fill=INK)
d.text((M, 100), "Design drawings dropped into main's real opening (7c19ee2, 1280x720 captures, cropped to the unit; real camera and timing). Flat-shaded, not final art. Stills only: nothing was played by hand.",
       font=font(FR, 26), fill=GREY)
d.text((M, 136), "Today's cage stays in the game until you pick. Sign text and keypads are proposals: each option also has a no-text, no-keypad version. Ranks are the judge's, before the fixes. OPTIONS.md.",
       font=font(FR, 26), fill=GREY)

y = HEAD_H
for r in ROWS:
    x0, y0, x1, y1 = M - 14, y, W - M + 14, y + ROW_H
    if r['rec']:
        d.rounded_rectangle((x0, y0, x1, y1), radius=14, fill=(226, 240, 230), outline=REC, width=8)
    else:
        d.rounded_rectangle((x0, y0, x1, y1), radius=14, fill=(244, 243, 239), outline=EDGE, width=2)
    cy = y0 + ROW_PAD
    d.text((M + 8, cy), r['name'], font=font(FB, 46), fill=INK)
    # rank badge (and recommended badge) on the right
    rb = font(FB, 34)
    rt = r['rank']
    tw = d.textlength(rt, font=rb)
    bx = x1 - 30 - tw
    if r['rec']:
        badge = 'RECOMMENDED (fixes applied)'
        bw = d.textlength(badge, font=rb)
        d.rounded_rectangle((bx - bw - 70, cy - 4, bx - 30, cy + 48), radius=10, fill=REC)
        d.text((bx - bw - 50, cy + 2), badge, font=rb, fill=(255, 255, 255))
    d.text((bx, cy + 2), rt, font=rb, fill=REC if r['rec'] else GREY)
    d.text((M + 8, cy + 62), r['how'], font=font(FR, 29), fill=INK)

    fy = y0 + ROW_PAD + CAP_H
    fx = M + 8
    lf = font(FR, 25)
    for path, crop, label in r['frames']:
        im = Image.open(path).convert('RGB')
        if crop: im = im.crop(crop)
        im = im.crop(BEAT_CROP)
        im = im.resize((FW, FH), Image.LANCZOS)
        sheet.paste(im, (fx, fy))
        d.rectangle((fx - 1, fy - 1, fx + FW, fy + FH), outline=(60, 62, 66), width=1)
        d.text((fx + 2, fy + FH + 8), label, font=lf, fill=INK)
        fx += FW + GAP
    # front elevation from the option's own construction drawing
    ep, ec = r['elev']
    el = Image.open(ep).convert('RGB').crop(ec)
    room = (W - M - 8) - fx
    sc = min(FH / el.height, room / el.width)
    el = el.resize((int(el.width * sc), int(el.height * sc)), Image.LANCZOS)
    sheet.paste(el, (fx, fy))
    d.rectangle((fx - 1, fy - 1, fx + el.width, fy + el.height), outline=(60, 62, 66), width=1)
    d.text((fx + 2, fy + FH + 8), 'Front elevation (construction drawing)', font=lf, fill=INK)
    y += ROW_H + GAP

d.text((M, H - FOOT_H + 18), "Full drawings, parts lists and every frame: option-a/, option-b/, option-c/ (strip.png and DESIGN.md in each). Judged 2026-10-11 from stills, code and measurements; no play, sound, export or device test.",
       font=font(FR, 24), fill=GREY)

sheet.save(S + '/sheet.png', optimize=True)
print(sheet.size)
