"""Round 10 (add7 fix round 3; copied from fix2/tools/package9.py): four-way pairs (main 76d3a50 |
round 6 | round 9, the build the round-3 reviews saw | round 10), crops of every fix, and the contact
sheet. Main and round 6 are round 8's render.sh captures with the round-8 driver
(add7/shots/raw8/{main,r6}); round 9 is its own capture with the same driver (raw9/add); round 10 is
this round's render.sh capture with the same driver (add7/shots/raw10/add), same routes, same container.
Run it AFTER luminaire_check10.py, measure10.py and pulse10.py: crops/ is emptied by hand before those
run (tools/run_package10.sh), and every other crop found there is added to the sheet. HUD hidden (the -clean frames), except the PAUSE crops, which need the HUD.
Phone: the game keeps 16:9, so a 2400x1080 phone shows its 1920x1080 image between pillar bars.
Writes add7/shots/pairs/, pairs/phone/, crops/ and sheet.png (old files there are removed first)."""
from __future__ import annotations

import glob
import json
import os

import numpy as np
from PIL import Image, ImageDraw, ImageFont

R = "scratchpad/real-slice"
SHOTS = os.path.join(R, "add7", "shots")
RAWDIR = {"main": os.path.join(SHOTS, "raw8", "main"), "r6": os.path.join(SHOTS, "raw8", "r6"), "r9": os.path.join(SHOTS, "raw9", "add"), "r10": os.path.join(SHOTS, "raw10", "add")}
PAIRS = os.path.join(SHOTS, "pairs")
CROPS = os.path.join(SHOTS, "crops")
FONT = os.path.join(R, "game-main", "apps", "game", "assets", "fonts", "Roboto-Variable.ttf")
COPIES = [("main", "MAIN 76d3a50"), ("r6", "ROUND 6"), ("r9", "ROUND 9 (reviewed)"), ("r10", "ROUND 10 (this fix)")]
STATES = [("s1-door-end-rest", "A", "s1 door end at rest"), ("s2-relay-wolf", "A", "s2 relay beat"),
          ("s3-bypass-crank", "B", "s3 cranking (4 of 8)"), ("s3-crank-B", "B", "s3 crank: push frame"),
          ("s3-crank-A", "B", "s3 crank: regrip frame"), ("s4-door-opening", "A", "s4 roller half up"),
          ("s4b-leaf-moving", "A", "s4b inner leaf sliding"), ("s5-door-open", "A", "s5 door open"),
          ("s6-walk-through", "A", "s6 walking through"), ("s7-safe-point", "A", "s7 safe point")]
BG = (18, 20, 24)


def f(size: int) -> ImageFont.FreeTypeFont:
    x = ImageFont.truetype(FONT, size)
    x.set_variation_by_axes([600, 100])
    return x


def path(copy, run, name):
    return os.path.join(RAWDIR[copy], run, name)


def frame(copy, route, shape, slug, clean=True):
    return Image.open(path(copy, f"{route}-{shape}", f"{slug}{'-clean' if clean else ''}.png")).convert("RGB")


def shot(copy, route, shape, slug):
    for s in json.load(open(path(copy, f"{route}-{shape}", "_run.json")))["shots"]:
        if s["slug"] == slug:
            return s
    raise KeyError(slug)


def phone(im):
    screen = Image.new("RGB", (2400, 1080), (0, 0, 0))
    screen.paste(im, ((2400 - im.width) // 2, (1080 - im.height) // 2))
    return screen


def row_of(ims, titles, band, size, gap=8):
    w, h = ims[0].size
    p = Image.new("RGB", (w * len(ims) + gap * (len(ims) - 1), h + band), BG)
    d = ImageDraw.Draw(p)
    for i, (im, t) in enumerate(zip(ims, titles)):
        p.paste(im, (i * (w + gap), band))
        d.text((i * (w + gap) + 6, max(band // 2 - size // 2 - 2, 1)), t, font=f(size), fill=(220, 225, 230))
    return p


def world_box(sh, box, W, H):
    cx, cy = (float(v) for v in sh["camera"].strip("()").split(","))
    s = float(sh["zoom"]) * W / 960.0
    x0, y0, x1, y1 = box
    return (int(round((x0 - cx) * s + W / 2)), int(round((y0 - cy) * s + H / 2)), int(round((x1 - cx) * s + W / 2)), int(round((y1 - cy) * s + H / 2)))


def labelled(p, label):
    out = Image.new("RGB", (p.width, p.height + 26), BG)
    out.paste(p, (0, 26))
    ImageDraw.Draw(out).text((6, 5), label, font=f(15), fill=(240, 220, 150))
    return out


# Crops of each fix, in world px (x0, y0, x1, y1) on the clean 1280x720 frames.
CROP_LIST = [
    ("c-cutaway-s7", "A", "s7-safe-point", (760.0, 370.0, 960.0, 545.0), 2, "Decision 1: the safe-point room's camera-side wall as a clean cutaway: one dark section poche, clean edges, no angles, anchors, ties, joints or damp foot; marker drawn above it"),
    ("c-cutaway-s1", "A", "s1-door-end-rest", (760.0, 396.0, 960.0, 545.0), 2, "Decision 1 at rest (door shut): the cut wall as a section poche"),
    ("c-cutaway-s5", "A", "s5-door-open", (760.0, 396.0, 960.0, 545.0), 2, "Decision 1, door open: the way in is the doorway"),
    ("k-marker-safe-point-s7", "A", "s7-safe-point", (800.0, 420.0, 870.0, 452.0), 4, "Real SHOULD 2: the engineer's control marker drawn above the near art, whole again at the safe point"),
    ("w-wolf-doorway-s7", "A", "s7-safe-point", (630.0, 360.0, 900.0, 455.0), 2, "Decision 2: WOLF comes to the open doorway at 'We made it.', facing the engineer (the MANUAL BYPASS gearbox is on the back wall behind him)"),
    ("w-wolf-doorway-wide-s7", "A", "s7-safe-point", (400.0, 300.0, 960.0, 545.0), 1, "Decision 2 at 1x: where WOLF stands while the safe point's line is up"),
    ("g-relief-spray-s3", "B", "s3-bypass-crank", (612.0, 334.0, 690.0, 446.0), 3, "(g) relief spray, unchanged since round 9 (alpha 0.2)"),
]


def crops():
    os.makedirs(CROPS, exist_ok=True)
    made = []
    for name, route, slug, box, k, label in CROP_LIST:
        ims = []
        for copy, _ in COPIES:
            im = frame(copy, route, "720", slug)
            b = world_box(shot(copy, route, "720", slug), box, im.width, im.height)
            ims.append(im.crop(b).resize(((b[2] - b[0]) * k, (b[3] - b[1]) * k), Image.Resampling.NEAREST))
        if k == 1 and box[2] - box[0] > 200:
            # wide crops: round 9 | round 10 only (main and round 6 are in the pairs)
            out = labelled(row_of([ims[2], ims[3]], [COPIES[2][1], COPIES[3][1]], 30, 14), label + "  (1x)")
        else:
            out = labelled(row_of(ims, [t for _, t in COPIES], 30, 14), label + "  (%dx, 1280x720 capture)" % k)
        out.save(os.path.join(CROPS, f"{name}-{k}x.png"))
        made.append((name, out))
    # (d) the beacons: crop round each anchor (from round 10's red globes; the far plate scrolls)
    for slug in ("s1-door-end-rest", "s5-door-open"):
        frames = {c: frame(c, "A", "720", slug) for c, _ in COPIES}
        sh = shot("r10", "A", "720", slug)
        s = float(sh["zoom"]) * 1280 / 960.0
        a = np.asarray(frames["r10"]).astype(int)
        from scipy import ndimage
        lab, n = ndimage.label((a[..., 0] > 120) & (a[..., 0] - a[..., 1] > 70) & (a[..., 0] - a[..., 2] > 70))
        cents = []
        for i in range(1, n + 1):
            ys, xs = np.nonzero(lab == i)
            if len(xs) >= 6 and ys.mean() < 260 and all(abs(xs.mean() - c[0]) > 30 for c in cents):
                cents.append((xs.mean(), ys.mean()))
        for i, (gx, gy) in enumerate(sorted(cents)[:2]):
            b = (int(gx - 26 * s), int(gy - 66 * s), int(gx + 26 * s), int(gy + 46 * s))
            ims = [frames[c].crop(b).resize(((b[2] - b[0]) * 3, (b[3] - b[1]) * 3), Image.Resampling.NEAREST) for c, _ in COPIES]
            side = "left" if i == 0 else "right"
            out = labelled(row_of(ims, [t for _, t in COPIES], 30, 14), f"(d) {side} lockdown beacon, {slug[:2]}: same lamp, globe and light art as round 9; round 10 pulses deeper and brighter (one pulse phase here; see p-beacon-pulse-*)  (3x)")
            name = f"d-beacon-{side}-{slug[:2]}"
            out.save(os.path.join(CROPS, f"{name}-3x.png"))
            made.append((name, out))
    # the luminaire against the PAUSE button, with the HUD, in o8 at 720, 1600x900 and phone
    for run, label, scale in (("O-720", "1280x720", 2), ("O-1600", "1600x900", 2), ("O-phone", "phone 2400x1080", 1)):
        ims = []
        titles = []
        for copy, t in COPIES:
            p = path(copy, run, "o8-heads-out.png")
            if not os.path.exists(p):
                continue
            im = Image.open(p).convert("RGB")
            W, H = im.size
            box = (int(W * 0.70), 0, W, int(H * 0.22))
            ims.append(im.crop(box).resize(((box[2] - box[0]) * scale, (box[3] - box[1]) * scale), Image.Resampling.NEAREST))
            titles.append(t)
        out = labelled(row_of(ims, titles, 30, 14), f"luminaire by the PAUSE button, opening o8, {label}, with the HUD ({scale}x)")
        name = f"l-luminaire-pause-o8-{run}"
        out.save(os.path.join(CROPS, f"{name}.png"))
        made.append((name, out))
    return made


def main():
    for d in (PAIRS, os.path.join(PAIRS, "phone"), CROPS):
        os.makedirs(d, exist_ok=True)
    for old in glob.glob(os.path.join(PAIRS, "*.png")) + glob.glob(os.path.join(PAIRS, "phone", "*.png")) :
        os.remove(old)
    rows = []
    titles = [t for _, t in COPIES]
    for slug, route, title in STATES:
        ims = [frame(c, route, "720", slug) for c, _ in COPIES]
        row_of(ims, [f"{t}   {title}" for t in titles], 40, 20).save(os.path.join(PAIRS, f"{slug}-720.png"))
        small = [im.resize((640, 360), Image.Resampling.LANCZOS) for im in ims]
        rows.append(row_of(small, [f"{t}: {title}" for t in titles], 26, 13))
    for slug, route, title in STATES:
        ims = []
        for c, _ in COPIES:
            ph = phone(frame(c, route, "phone", slug))
            ph.save(os.path.join(PAIRS, "phone", f"{c}-{slug}.png"))
            ims.append(ph)
        row_of(ims, [f"{t}   {title} (phone 2400x1080)" for t in titles], 52, 30).save(os.path.join(PAIRS, f"{slug}-phone.png"))
        if slug in ("s1-door-end-rest", "s3-crank-B", "s4b-leaf-moving", "s7-safe-point"):
            small = [im.resize((640, 288), Image.Resampling.LANCZOS) for im in ims]
            rows.append(row_of(small, [f"{t}: {title} (phone shape)" for t in titles], 26, 13))
    made = crops()
    mine = {n for n, _ in made}
    for p in sorted(glob.glob(os.path.join(CROPS, "*.png"))):
        n = os.path.splitext(os.path.basename(p))[0]
        if not any(n.startswith(m) for m in mine):
            made.append((n, Image.open(p).convert("RGB")))
    width = rows[0].width
    packed, cur, x = [], [], 0
    for name, im in made:
        im2 = im.copy()
        im2.thumbnail((width // 2 - 8, 460))
        if x + im2.width > width and cur:
            packed.append(cur)
            cur, x = [], 0
        cur.append(im2)
        x += im2.width + 8
    if cur:
        packed.append(cur)
    for group in packed:
        r = Image.new("RGB", (width, max(i.height for i in group)), BG)
        x = 0
        for i in group:
            r.paste(i, (x, 0))
            x += i.width + 8
        rows.append(r)
    for o in ("o5-wolf-steps-out.png", "o7-director-order.png", "o8-heads-out.png"):
        p = Image.new("RGB", (width, 360 + 26), BG)
        p.paste(Image.open(path("main", "O-720", o)).convert("RGB").resize((640, 360), Image.Resampling.LANCZOS), (0, 26))
        p.paste(Image.open(path("r10", "O-720", o)).convert("RGB").resize((640, 360), Image.Resampling.LANCZOS), (648, 26))
        p.paste(Image.open(os.path.join(SHOTS, "opening-diff", o)).convert("RGB").resize((640, 360), Image.Resampling.LANCZOS), (1296, 26))
        d = ImageDraw.Draw(p)
        d.text((6, 6), f"OPENING {o[:2]}: main", font=f(13), fill=(220, 225, 230))
        d.text((654, 6), "round 10", font=f(13), fill=(220, 225, 230))
        d.text((1302, 6), "diff (over main's frame): pink outside the beacon zones (cyan)", font=f(13), fill=(220, 225, 230))
        rows.append(p)
    total = sum(r.height for r in rows) + 6 * (len(rows) - 1)
    sheet = Image.new("RGB", (max(r.width for r in rows), total), (8, 9, 11))
    y = 0
    for r in rows:
        sheet.paste(r, (0, y))
        y += r.height + 6
    sheet.save(os.path.join(SHOTS, "sheet.png"))
    print("sheet", sheet.size, "pairs", len(glob.glob(os.path.join(PAIRS, "*.png"))), "crops", len(made))


if __name__ == "__main__":
    main()
