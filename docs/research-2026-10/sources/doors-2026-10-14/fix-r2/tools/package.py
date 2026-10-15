"""Fix round 2 (was fix round 1's): builds doors-r1/shots (regenerated whole, so nothing is stale): pairs/ (before | after), crops/ (3x door crops, before | after), sheet.png and
sheet-phone.png, and perf.json (per-state numbers from both render.sh runs). Scratch only."""
import json
import os
import sys

from PIL import Image, ImageDraw, ImageFont

S = sys.argv[1]
CAP = os.path.join(S, "fix-r2", "captures")
OUT = os.path.join(S, "shots")
FONT = ImageFont.load_default()
BASE = 960.0

# world rects (x0, x1, y0, y1) of each door, by slug prefix
DOORS = [
    (("r01", "r02", "r03"), "records-entry", (-45.0, 150.0, 130.0, 470.0)),
    (("r09", "r10", "r11"), "junction-entry", (-10.0, 200.0, 130.0, 470.0)),
    (("r04", "r05", "r06", "r07", "r08"), "records-exit", (740.0, 950.0, 130.0, 470.0)),
    (("j01", "j02", "j03", "j04", "j05", "j06", "j07"), "junction-blast", (380.0, 580.0, 130.0, 470.0)),
    (("j08", "j09", "j10", "j11", "j12", "j13", "j14", "j15"), "junction-exit", (830.0, 1032.0, 130.0, 470.0)),
]


def load(run):
    path = os.path.join(CAP, run, "_run.json")
    if not os.path.exists(path):
        return None
    d = json.load(open(path))
    d["by"] = {s["slug"]: s for s in d["shots"]}
    d["dir"] = os.path.join(CAP, run)
    return d


def label(im, text, color=(255, 230, 0)):
    d = ImageDraw.Draw(im)
    d.rectangle([0, 0, im.width, 16], fill=(0, 0, 0))
    d.text((4, 2), text, fill=color, font=FONT)
    return im


def blank(size, text):
    im = Image.new("RGB", size, (24, 24, 28))
    ImageDraw.Draw(im).text((20, size[1] // 2), text, fill=(200, 200, 200), font=FONT)
    return im


def shot(run, slug, clean=False):
    if run is None or slug not in run["by"]:
        return None
    return Image.open(os.path.join(run["dir"], slug + ("-clean" if clean else "") + ".png")).convert("RGB")


def crop(run, slug, rect, k=3):
    im = shot(run, slug, True)
    if im is None:
        return None
    c = run["by"][slug]["canvas"]
    f = im.width / BASE
    x0, x1, y0, y1 = rect
    box = [int((c[0] * x0 + c[4]) * f), int((c[3] * y0 + c[5]) * f), int((c[0] * x1 + c[4]) * f), int((c[3] * y1 + c[5]) * f)]
    box = [max(0, box[0]), max(0, box[1]), min(im.width, box[2]), min(im.height, box[3])]
    if box[2] - box[0] < 8:
        return None
    part = im.crop(box)
    return part.resize((part.width * k, part.height * k), Image.NEAREST)


def side(a, b, la, lb):
    h = max(x.height for x in (a, b) if x is not None) if (a or b) else 100
    w = max(x.width for x in (a, b) if x is not None)
    a = a if a is not None else blank((w, h), "no equivalent frame on main")
    b = b if b is not None else blank((w, h), "not captured")
    out = Image.new("RGB", (a.width + b.width + 8, max(a.height, b.height)), (0, 0, 0))
    out.paste(label(a.copy(), la), (0, 0))
    out.paste(label(b.copy(), lb), (a.width + 8, 0))
    return out


def main():
    before, after = load("before-1280"), load("after-1280")
    pb, pa = load("before-phone"), load("after-phone")
    import shutil
    for sub in ("pairs", "crops"):
        shutil.rmtree(os.path.join(OUT, sub), ignore_errors=True)
        os.makedirs(os.path.join(OUT, sub), exist_ok=True)
    slugs = sorted(set(after["by"]) | set(before["by"] if before else []))
    commit = "cec75f6"  # origin/main the patch applies to (fix round 2)
    for slug in slugs:
        b, a = shot(before, slug), shot(after, slug)
        side(b, a, "BEFORE main %s  %s  (render.sh 1280x720)" % (commit, slug), "AFTER doors fix round 2  %s  (render.sh 1280x720)" % slug).save(os.path.join(OUT, "pairs", slug + ".png"))
        if pb or pa:
            b2, a2 = shot(pb, slug), shot(pa, slug)
            if b2 or a2:
                side(b2, a2, "BEFORE main %s  %s  (2400x1080)" % (commit, slug), "AFTER  %s  (2400x1080)" % slug).save(os.path.join(OUT, "pairs", slug + "-phone.png"))
        for prefixes, door, rect in DOORS:
            if slug.startswith(prefixes):
                cb, ca = crop(before, slug, rect), crop(after, slug, rect)
                if cb or ca:
                    side(cb, ca, "BEFORE %s 3x" % slug, "AFTER %s 3x (%s)" % (slug, door)).save(os.path.join(OUT, "crops", "%s-%s-3x.png" % (slug, door)))
    # contact sheets: the after run, every state, 2 columns of 640 px
    for run, name in ((after, "sheet.png"), (pa, "sheet-phone.png")):
        if run is None:
            continue
        tiles = []
        for s in run["shots"]:
            im = shot(run, s["slug"])
            w = 640
            im = im.resize((w, int(im.height * w / im.width)))
            tiles.append(label(im, "%s  eng x %.0f  WOLF x %.0f  %s" % (s["slug"], s["engineer_x"], s["wolf_x"], s["beat"])))
        cols = 3
        h = max(t.height for t in tiles)
        rows = (len(tiles) + cols - 1) // cols
        sheet = Image.new("RGB", (cols * 640 + (cols - 1) * 4, rows * (h + 4)), (10, 10, 12))
        for i, t in enumerate(tiles):
            sheet.paste(t, ((i % cols) * 644, (i // cols) * (h + 4)))
        sheet.save(os.path.join(OUT, name))
    perf = {"before": before["perf"] if before else [], "after": after["perf"]}
    json.dump(perf, open(os.path.join(OUT, "perf.json"), "w"), indent=1)
    print("packaged", len(slugs), "states")


main()
