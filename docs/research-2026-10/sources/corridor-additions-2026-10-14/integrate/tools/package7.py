"""Round 7 integration: three-way pairs (main 76d3a50 | round 6 | round 7 additions), 3x crops of
each addition, and the contact sheet, all from this round's render.sh captures with one driver
(add7/integrate/driver) in one container: add7/shots/raw7/{main,r6,add}/{A,B}-{720,phone}/, HUD
hidden (the -clean frames). Phone: the game keeps 16:9, so a 2400x1080 phone shows its 1920x1080
image between 240 px pillar bars; the phone frames are the captured image placed in that screen.
Writes add7/shots/pairs/, add7/shots/pairs/phone/, add7/shots/crops/ and add7/shots/sheet.png."""
from __future__ import annotations

import glob
import json
import os

import numpy as np
from PIL import Image, ImageDraw, ImageFont

R = "scratchpad/real-slice"
RAW = os.path.join(R, "add7", "shots", "raw7")
SHOTS = os.path.join(R, "add7", "shots")
PAIRS = os.path.join(SHOTS, "pairs")
CROPS = os.path.join(SHOTS, "crops")
FONT = os.path.join(R, "game-main", "apps", "game", "assets", "fonts", "Roboto-Variable.ttf")
COPIES = [("main", "MAIN 76d3a50"), ("r6", "ROUND 6 (game-slice)"), ("add", "ROUND 7 ADDITIONS (game-add)")]
STATES = [("s1-door-end-rest", "A", "s1 door end at rest"), ("s2-relay-wolf", "A", "s2 relay beat, WOLF on the contact"),
          ("s3-bypass-crank", "B", "s3 cranking the bypass (4 of 8)"), ("s3-crank-B", "B", "s3 crank strip: just after a tick (push)"),
          ("s3-crank-A", "B", "s3 crank strip: later in the tick (regrip)"), ("s4-door-opening", "A", "s4 opening: roller half up"),
          ("s4b-leaf-moving", "A", "s4b opening: roller 3/4 up, inner leaf sliding"), ("s5-door-open", "A", "s5 door open"),
          ("s6-walk-through", "A", "s6 walking through"), ("s7-safe-point", "A", "s7 safe point")]
BG = (18, 20, 24)


def f(size: int) -> ImageFont.FreeTypeFont:
    x = ImageFont.truetype(FONT, size)
    x.set_variation_by_axes([600, 100])
    return x


def frame(copy: str, route: str, shape: str, slug: str) -> Image.Image:
    return Image.open(os.path.join(RAW, copy, f"{route}-{shape}", f"{slug}-clean.png")).convert("RGB")


def shot(copy: str, route: str, shape: str, slug: str) -> dict:
    for s in json.load(open(os.path.join(RAW, copy, f"{route}-{shape}", "_run.json")))["shots"]:
        if s["slug"] == slug:
            return s
    raise KeyError(slug)


def phone(im: Image.Image) -> Image.Image:
    screen = Image.new("RGB", (2400, 1080), (0, 0, 0))
    screen.paste(im, ((2400 - im.width) // 2, (1080 - im.height) // 2))
    return screen


def triple(ims: list[Image.Image], titles: list[str], band: int, size: int) -> Image.Image:
    w, h = ims[0].size
    p = Image.new("RGB", (w * 3 + 16, h + band), BG)
    d = ImageDraw.Draw(p)
    for i, (im, t) in enumerate(zip(ims, titles)):
        p.paste(im, (i * (w + 8), band))
        d.text((i * (w + 8) + 6, max(band // 2 - size // 2 - 2, 1)), t, font=f(size), fill=(220, 225, 230))
    return p


def world_box(sh: dict, box: tuple[float, float, float, float], W: int, H: int) -> tuple[int, int, int, int]:
    cx, cy = (float(v) for v in sh["camera"].strip("()").split(","))
    s = float(sh["zoom"]) * W / 960.0
    x0, y0, x1, y1 = box
    return (int(round((x0 - cx) * s + W / 2)), int(round((y0 - cy) * s + H / 2)), int(round((x1 - cx) * s + W / 2)), int(round((y1 - cy) * s + H / 2)))


def red_centres(img: np.ndarray, min_px: int) -> list[tuple[float, float]]:
    from scipy import ndimage
    r, g, b = img[..., 0], img[..., 1], img[..., 2]
    lab, n = ndimage.label((r > 120) & (r - g > 70) & (r - b > 70))
    out = []
    for i in range(1, n + 1):
        ys, xs = np.nonzero(lab == i)
        if len(xs) >= min_px:
            out.append((float(xs.mean()), float(ys.mean())))
    return out


def beacon_anchors(add: Image.Image, main: Image.Image, s: float) -> list[tuple[float, float]]:
    """The beacons' screen anchors in an additions frame: red globes where main has a red lens
    within 9 world px and the pixels changed (as opening_diff7.py)."""
    a = np.asarray(add).astype(int)
    m = np.asarray(main).astype(int)
    change = np.abs(a - m).max(-1)
    lenses = red_centres(m, 6)
    anchors: list[tuple[float, float]] = []
    for gx, gy in red_centres(a, 6):
        ax, ay = gx - 0.89 * s, gy - 5.2 * s
        if any(np.hypot(lx - ax, ly - ay) <= 9 * s for lx, ly in lenses) and float(change[int(gy - 2 * s):int(gy + 2 * s) + 1, int(gx - 2 * s):int(gx + 2 * s) + 1].mean()) > 20:
            if all(np.hypot(ax - bx, ay - by) > 6 * s for bx, by in anchors):
                anchors.append((ax, ay))
    return sorted(anchors)


# Crops of each addition, in world px (x0, y0, x1, y1) on the clean 1280x720 frames.
CROP_LIST = [
    ("a-blast-frame-s1", "A", "s1-door-end-rest", (700.0, 262.0, 812.0, 330.0), "(a) steel blast frame: armour head plates and bolts over the hood"),
    ("b-sign-and-marks-s1", "A", "s1-door-end-rest", (712.0, 196.0, 806.0, 300.0), "(b, e) RESTRICTED AREA plate; SECTOR 4B and DOOR 4B-07 kept"),
    ("c-inner-leaf-s4", "A", "s4-door-opening", (708.0, 296.0, 812.0, 452.0), "(c) roller half up: the inner blast leaf behind it"),
    ("c-inner-leaf-s4b", "A", "s4b-leaf-moving", (708.0, 296.0, 812.0, 452.0), "(c) the inner leaf sliding back into its pocket"),
    ("c-inner-leaf-s5", "A", "s5-door-open", (708.0, 296.0, 812.0, 452.0), "(c) open: the leaf's striped edge parked in the pocket's mouth"),
    ("f-crank-B", "B", "s3-crank-B", (650.0, 352.0, 714.0, 446.0), "(f) crank, push frame: glove on the rim"),
    ("f-crank-A", "B", "s3-crank-A", (650.0, 352.0, 714.0, 446.0), "(f) crank, regrip frame: glove on the rim"),
    ("g-relief-jet-s3", "B", "s3-bypass-crank", (612.0, 334.0, 672.0, 392.0), "(g) relief valve and coolant jet (was the glowing disc)"),
    ("h-strap-s1", "A", "s1-door-end-rest", (794.0, 286.0, 820.0, 334.0), "(h) second saddle strap on the lamp conduit"),
]


def crops() -> list[tuple[str, Image.Image]]:
    os.makedirs(CROPS, exist_ok=True)
    made = []
    for name, route, slug, box, label in CROP_LIST:
        ims = []
        for copy, _ in COPIES:
            im = frame(copy, route, "720", slug)
            b = world_box(shot(copy, route, "720", slug), box, im.width, im.height)
            ims.append(im.crop(b).resize(((b[2] - b[0]) * 3, (b[3] - b[1]) * 3), Image.Resampling.NEAREST))
        p = triple(ims, [t for _, t in COPIES], 30, 14)
        ImageDraw.Draw(p).text((6, p.height - 2), "", font=f(12))
        out = Image.new("RGB", (p.width, p.height + 26), BG)
        out.paste(p, (0, 26))
        ImageDraw.Draw(out).text((6, 5), label + "  (3x, 1280x720 capture)", font=f(15), fill=(240, 220, 150))
        out.save(os.path.join(CROPS, f"{name}-3x.png"))
        made.append((name, out))
    # (d) the beacons, found in each frame (the far plate scrolls with parallax)
    for slug, route in (("s1-door-end-rest", "A"), ("s5-door-open", "A")):
        frames = {c: frame(c, route, "720", slug) for c, _ in COPIES}
        sh = shot("add", route, "720", slug)
        s = float(sh["zoom"]) * 1280 / 960.0
        anchors = beacon_anchors(frames["add"], frames["main"], s)
        for i, (ax, ay) in enumerate(anchors):
            b = (int(ax - 24 * s), int(ay - 60 * s), int(ax + 24 * s), int(ay + 30 * s))
            ims = [frames[c].crop(b).resize(((b[2] - b[0]) * 3, (b[3] - b[1]) * 3), Image.Resampling.NEAREST) for c, _ in COPIES]
            p = triple(ims, [t for _, t in COPIES], 30, 14)
            out = Image.new("RGB", (p.width, p.height + 26), BG)
            out.paste(p, (0, 26))
            side = "left" if i == 0 else "right"
            ImageDraw.Draw(out).text((6, 5), f"(d) {side} lockdown beacon, {slug[:2]}: caged red lamp on a wall bracket (was a drawn red chip)  (3x)", font=f(15), fill=(240, 220, 150))
            name = f"d-beacon-{side}-{slug[:2]}"
            out.save(os.path.join(CROPS, f"{name}-3x.png"))
            made.append((name, out))
    return made


def main() -> None:
    os.makedirs(os.path.join(PAIRS, "phone"), exist_ok=True)
    for old in glob.glob(os.path.join(PAIRS, "*.png")) + glob.glob(os.path.join(PAIRS, "phone", "*.png")):
        os.remove(old)
    rows = []
    titles720 = [t for _, t in COPIES]
    for slug, route, title in STATES:
        ims = [frame(c, route, "720", slug) for c, _ in COPIES]
        triple(ims, [f"{t}   {title}" for t in titles720], 40, 20).save(os.path.join(PAIRS, f"{slug}-720.png"))
        small = [im.resize((640, 360), Image.Resampling.LANCZOS) for im in ims]
        rows.append(triple(small, [f"{t}: {title}" for t in titles720], 26, 13))
    for slug, route, title in STATES:
        ims = []
        for c, _ in COPIES:
            ph = phone(frame(c, route, "phone", slug))
            ph.save(os.path.join(PAIRS, "phone", f"{c}-{slug}.png"))
            ims.append(ph)
        triple(ims, [f"{t}   {title} (phone 2400x1080)" for t in titles720], 52, 30).save(os.path.join(PAIRS, f"{slug}-phone.png"))
        if slug in ("s1-door-end-rest", "s4b-leaf-moving", "s5-door-open"):
            small = [im.resize((640, 288), Image.Resampling.LANCZOS) for im in ims]
            rows.append(triple(small, [f"{t}: {title} (phone shape)" for t in titles720], 26, 13))
    made = crops()
    # crops, packed into rows of the sheet's width
    width = 640 * 3 + 16
    row = Image.new("RGB", (width, 1), BG)
    x = 0
    packed = []
    cur = []
    for name, im in made:
        im2 = im.copy()
        im2.thumbnail((width // 2 - 8, 420))
        if x + im2.width > width and cur:
            packed.append(cur)
            cur, x = [], 0
        cur.append(im2)
        x += im2.width + 8
    if cur:
        packed.append(cur)
    for group in packed:
        h = max(i.height for i in group)
        r = Image.new("RGB", (width, h), BG)
        x = 0
        for i in group:
            r.paste(i, (x, 0))
            x += i.width + 8
        rows.append(r)
    # opening: main's frame and the diff (pink = changed outside the beacon zones, over main's frame)
    for o in ("o5-wolf-steps-out.png", "o7-director-order.png", "o8-heads-out.png"):
        p = Image.new("RGB", (width, 360 + 26), BG)
        p.paste(Image.open(os.path.join(R, "shots", "raw5", "main", "O-720", o)).convert("RGB").resize((640, 360), Image.Resampling.LANCZOS), (0, 26))
        p.paste(Image.open(os.path.join(RAW, "add", "O-720", o)).convert("RGB").resize((640, 360), Image.Resampling.LANCZOS), (648, 26))
        p.paste(Image.open(os.path.join(SHOTS, "opening-diff", o)).convert("RGB").resize((640, 360), Image.Resampling.LANCZOS), (1296, 26))
        d = ImageDraw.Draw(p)
        d.text((6, 6), f"OPENING {o[:2]}: main", font=f(13), fill=(220, 225, 230))
        d.text((654, 6), "round 7 additions", font=f(13), fill=(220, 225, 230))
        d.text((1302, 6), "diff over main's frame: pink outside the beacon zones (cyan)", font=f(13), fill=(220, 225, 230))
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
