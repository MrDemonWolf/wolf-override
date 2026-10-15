"""Round 7 integration: rule 5 on the opening frames o0-o8 (render.sh, 1280x720).

The additions copy (game-add, add7/shots/raw7/add/O-720) is compared pixel by pixel with
  - main 76d3a50: round 4's render.sh runs shots/raw5/main/O-720, O-720-repeat and O-720-r3 (main has
    not changed; same driver, same container), and
  - round 6 (game-slice): shots/raw6/slice/O-720.
Same-copy run-to-run noise (the old bay lamp's flicker phase) is left out first: a pixel whose
difference is no larger than the largest difference between two runs of the SAME copy within 2 px
of it is noise. Runs used: main O-720/-repeat/-r3, round 6 O-720/-r2, additions O-720/-r2.

Rule 5 for this round: everything left of world x 540 stays identical to main apart from main's
ambient dust, EXCEPT the two corridor beacons. Each beacon's zone is the union of what main draws
for it (the 90x90 additive glow, a 14x9 housing) and what the additions draw (fixture with its
conduit, globe, guard, light), in world px from its anchor: x -45..45, y -55..45, scaled by the
frame's zoom, plus 3 screen px. The anchor is found in the frame from the beacon's red globe
(additions) and checked against main's red lens. Outside the beacon zones and left of world x 540:
against round 6 every pixel must match (neither has dust); against main every blob must be dust
(small, brighter in main). Right of world x 540 is reported apart (the round's own span in o7/o8).

Writes add7/shots/opening-diff.json and add7/shots/opening-diff/<frame>.png (pink over MAIN's
frame: changed pixels outside the beacon zones; cyan outline: the beacon zones; labelled)."""
from __future__ import annotations

import json
import os

import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage

R = "scratchpad/real-slice"
RUNS = {
    "main": [os.path.join(R, "shots", "raw5", "main", r) for r in ("O-720", "O-720-repeat", "O-720-r3")],
    "r6": [os.path.join(R, "shots", "raw6", "slice", r) for r in ("O-720", "O-720-r2")],
    "add": [os.path.join(R, "add7", "shots", "raw7", "add", r) for r in ("O-720", "O-720-r2")],
}
OUT = os.path.join(R, "add7", "shots", "opening-diff")
FRAMES = ["o0-room-opening", "o1-standby", "o2-wolf-wakes", "o3-latch-breaks", "o4-gate-folding", "o5-wolf-steps-out", "o6-director-line", "o7-director-order", "o8-heads-out"]
DUST_MAX = 44
ZONE = (-45.0, 45.0, -55.0, 45.0)  # world px from the anchor: x0, x1, y0, y1
GLOBE_FROM_ANCHOR = (0.89, 5.2)  # the painted globe's centre from the anchor, world px (corridor-beacons placement)


def load(path: str) -> np.ndarray:
    return np.asarray(Image.open(path).convert("RGB")).astype(int)


def noise_level(name: str) -> np.ndarray | int:
    level = None
    for runs in RUNS.values():
        imgs = [load(os.path.join(r, name)) for r in runs if os.path.exists(os.path.join(r, name))]
        for i in range(len(imgs)):
            for j in range(i + 1, len(imgs)):
                d = np.abs(imgs[i] - imgs[j]).max(-1)
                level = d if level is None else np.maximum(level, d)
    return ndimage.maximum_filter(level, size=5) if level is not None else 0


def red_centres(img: np.ndarray, min_px: int) -> list[tuple[float, float, int]]:
    r, g, b = img[..., 0], img[..., 1], img[..., 2]
    red = (r > 120) & (r - g > 70) & (r - b > 70)
    lab, n = ndimage.label(red)
    out = []
    for i in range(1, n + 1):
        ys, xs = np.nonzero(lab == i)
        if len(xs) >= min_px:
            out.append((float(xs.mean()), float(ys.mean()), int(len(xs))))
    return out


def blobs(diff: np.ndarray, signed: np.ndarray, d: np.ndarray) -> tuple[list, int]:
    lab, n = ndimage.label(ndimage.binary_dilation(diff, iterations=1))
    big = []
    for i, sl in enumerate(ndimage.find_objects(lab)):
        h = sl[0].stop - sl[0].start
        w = sl[1].stop - sl[1].start
        inside = (lab[sl] == i + 1) & diff[sl]
        brighter_in_ref = float(signed[sl][inside].mean()) > 0 if inside.any() else True
        if max(h, w) > DUST_MAX or not brighter_in_ref:
            big.append([int(sl[1].start), int(sl[0].start), int(w), int(h), int(d[sl].max()), brighter_in_ref])
    return big, int(n)


def main() -> None:
    os.makedirs(OUT, exist_ok=True)
    cams = {s["slug"]: s for s in json.load(open(os.path.join(RUNS["add"][0], "_run.json")))["shots"]}
    main_cams = {s["slug"]: s for s in json.load(open(os.path.join(RUNS["main"][0], "_run.json")))["shots"]}
    rows = []
    for slug in FRAMES:
        name = slug + ".png"
        add = load(os.path.join(RUNS["add"][0], name))
        H, W = add.shape[:2]
        shot = cams[slug]
        assert shot["camera"] == main_cams[slug]["camera"] and abs(shot["zoom"] - main_cams[slug]["zoom"]) < 1e-6, slug
        cx = float(shot["camera"].strip("()").split(",")[0])
        z = float(shot["zoom"])
        s = z * W / 960.0
        sx540 = int((540.0 - cx) * s + W / 2)
        noise = noise_level(name)
        # Beacon anchors from the additions' red globes. A red cluster is a beacon only where main has
        # a red lens within 9 world px of it AND the pixels there changed (main's other reds, the
        # terminal screen and the cage's lights, are the same in both and are left out); clusters of
        # one globe split by its guard bars are merged.
        main_img = load(os.path.join(RUNS["main"][0], name))
        main_lenses_all = red_centres(main_img, 6)
        change = np.abs(main_img - add).max(-1)
        anchors = []
        main_lenses = []
        for gx, gy, _ in red_centres(add, 6):
            ax, ay = gx - GLOBE_FROM_ANCHOR[0] * s, gy - GLOBE_FROM_ANCHOR[1] * s
            near = [m for m in main_lenses_all if np.hypot(m[0] - ax, m[1] - ay) <= 9.0 * s]
            y0, y1, x0, x1 = int(max(gy - 2 * s, 0)), int(gy + 2 * s) + 1, int(max(gx - 2 * s, 0)), int(gx + 2 * s) + 1
            changed = float(change[y0:y1, x0:x1].mean()) > 20.0
            if near and changed:
                if all(np.hypot(ax - bx, ay - by) > 6.0 * s for bx, by in anchors):
                    anchors.append((ax, ay))
                main_lenses += [m for m in near if m not in main_lenses]
        zone = np.zeros((H, W), bool)
        boxes = []
        for ax, ay in anchors:
            x0, x1 = int(np.floor(ax + ZONE[0] * s - 3)), int(np.ceil(ax + ZONE[1] * s + 3))
            y0, y1 = int(np.floor(ay + ZONE[2] * s - 3)), int(np.ceil(ay + ZONE[3] * s + 3))
            zone[max(y0, 0):max(y1, 0), max(x0, 0):max(x1, 0)] = True
            boxes.append([x0, y0, x1 - x0, y1 - y0])
        # every main lens matched to a beacon sits in its zone (the beacon is where main's was)
        lens_in_zone = all(zone[min(max(int(my), 0), H - 1), min(max(int(mx), 0), W - 1)] for mx, my, _ in main_lenses)
        row = {"frame": name, "camera": shot["camera"], "zoom": z, "screen_x_of_world_540": sx540, "beacon_anchors_screen": [[round(a, 1), round(b, 1)] for a, b in anchors],
               "main_red_lenses_screen": [[round(a, 1), round(b, 1)] for a, b, _ in main_lenses], "main_lenses_inside_beacon_zones": lens_in_zone, "beacon_zones_xywh": boxes}
        vis_base = load(os.path.join(RUNS["main"][0], name))
        outside_mask = None
        for ref_name, ref_path in (("main", RUNS["main"][0]), ("main_repeat", RUNS["main"][1]), ("main_r3", RUNS["main"][2]), ("round6", RUNS["r6"][0])):
            ref = load(os.path.join(ref_path, name))
            d = np.abs(ref - add).max(-1)
            noise_px = int(((d > 0) & (d <= noise)).sum())
            d = np.where(d <= noise, 0, d)
            right = d[:, max(sx540, 0):] if sx540 < W else None
            right_px = int((right > 0).sum()) if right is not None else None
            left = d.copy()
            left[:, max(sx540, 0):] = 0
            in_zone_px = int(((left > 0) & zone).sum())
            left[zone] = 0
            diff = left > 0
            signed = (ref - add).mean(-1)
            big, n = blobs(diff, signed, left)
            r = {"noise_px_left_out": noise_px, "beacon_zone_px_differing": in_zone_px, "outside_zones_left_of_540_px": int(diff.sum()), "outside_zones_blobs": n,
                 "outside_zones_blobs_not_dust": big, "right_of_540_px": right_px}
            if ref_name == "round6":
                r["pass"] = int(diff.sum()) == 0
            else:
                r["pass"] = not big
            row["vs_" + ref_name] = r
            if ref_name == "main":
                outside_mask = diff
        rows.append(row)
        out = (vis_base * 0.35).astype(np.uint8)
        out[outside_mask] = [255, 40, 200]
        im = Image.fromarray(out)
        dr = ImageDraw.Draw(im)
        for x, y, w, h in boxes:
            dr.rectangle([x, y, x + w, y + h], outline=(80, 220, 255), width=2)
        if sx540 < W:
            dr.line([(sx540, 0), (sx540, H)], fill=(255, 210, 60), width=1)
        dr.rectangle([0, 0, W, 22], fill=(0, 0, 0))
        dr.text((6, 5), f"{slug} (over main's frame): pink = additions differ from main outside the beacon zones (cyan); yellow = world x 540", fill=(230, 230, 230))
        im.save(os.path.join(OUT, name))
    json.dump(rows, open(os.path.join(R, "add7", "shots", "opening-diff.json"), "w"), indent=1)
    for r in rows:
        m, s6 = r["vs_main"], r["vs_round6"]
        print(r["frame"], "anchors", r["beacon_anchors_screen"], "main lenses in zones", r["main_lenses_inside_beacon_zones"],
              "| vs main: zone px", m["beacon_zone_px_differing"], "outside px", m["outside_zones_left_of_540_px"], "non-dust", m["outside_zones_blobs_not_dust"], "right", m["right_of_540_px"],
              "| vs r6: zone px", s6["beacon_zone_px_differing"], "outside px", s6["outside_zones_left_of_540_px"], "right", s6["right_of_540_px"],
              "| main_repeat pass", r["vs_main_repeat"]["pass"], "main_r3 pass", r["vs_main_r3"]["pass"])


if __name__ == "__main__":
    main()
