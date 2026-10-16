"""Fix round 2 (review r2, N3; was rgrade.py, fix round 1 M1): grades cleaned door-end layers in the records track's format (Records exit and
entry, the junction entry) into their rooms' value plan (grade.py). Per door end: row gains from the
cross-wall's concrete face at 0.70x the room's back wall at the same height, applied to the wall, its
column and stub; the passage or vestibule behind the doorway at PASSAGE_RATIO of the room; the leaf faces
by one gain (the median of the wall's gains over the door's rows); lenses keep their value.
usage: rgrade2.py TRACK_DIR piece:ref[,piece:ref]   e.g. rgrade.py ../records exit:records-exit entry:records-entry
Writes TRACK_DIR/layers/graded/ (same names) and gains.json."""
from __future__ import annotations

import json
import os
import shutil
import sys

import numpy as np
from scipy import ndimage
from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import grade2 as G  # noqa: E402  (fix round 2: linear, at the corner)
import leafwear as LW  # noqa: E402  (fix round 3: designed wear on the leaf faces)


CONTAINER_FRAC = 0.95


def mask(dirp, layer, names, shape):
    u = np.zeros(shape)
    for n in names:
        p = os.path.join(dirp, f"{layer}--{n}.png")
        if os.path.exists(p):
            u = np.maximum(u, np.asarray(Image.open(p)).astype(np.float64) / 255.0)
    return u


# Fix round 3 (human r3: "the light battens still read as white dashes at the screen edges at 1x"): the
# passage batten's opal diffuser was clipped white (1.0 linear) and its body sat at the wall's own value
# (0.007-0.015), so only a 1 px white line showed. A lit LED batten seen from below reads as a frosted
# strip, bright but not burnt out, in the colour of its light, with its grey housing, clips and end caps
# showing round it in its own spill. Linear medians: diffuser BATTEN_LENS (cool), housing BATTEN_BODY,
# end caps BATTEN_CAP; the paint's own variation inside each part is kept.
BATTEN_LENS, BATTEN_BODY, BATTEN_CAP = 0.28, 0.034, 0.022  # lens: a frosted strip, about sRGB 145 (round 2's white came from the detail lift; see below)
BATTEN_TINT = np.array([0.86, 0.97, 1.0])


def batten_r3(out, md, shape):
    a = np.asarray(out).astype(np.float64)
    lin = G.to_lin(a.astype(np.uint8))
    lum = (lin * G.W709).sum(-1)
    for names, target, tint in ((["light_diffuser"], BATTEN_LENS, BATTEN_TINT), (["light_body"], BATTEN_BODY, None), (["light_cap0", "light_cap1"], BATTEN_CAP, None)):
        m = mask(md, "beyond", names, shape)
        sel = (m > 0.5) & (a[..., 3] > 200)
        if sel.sum() < 4:
            continue
        med = float(np.median(lum[sel]))
        new = lin * (target / max(med, 1e-6))
        if tint is not None:
            # a frosted strip: one even value with the paint's variation, in the light's colour
            new = np.clip(new, 0, 1)
            nl = (new * G.W709).sum(-1, keepdims=True)
            new = nl * tint / (tint * G.W709).sum()
        a[..., :3] = a[..., :3] * (1 - m[..., None]) + G.to_srgb8(np.clip(new, 0, 1)).astype(np.float64) * m[..., None]
    return np.clip(a + 0.5, 0, 255).astype(np.uint8)


def main():
    track = os.path.abspath(sys.argv[1])
    L = os.path.join(track, "layers")
    OUT = os.path.join(L, "graded")
    os.makedirs(OUT, exist_ok=True)
    report = {}
    leaf_gains = []
    for arg in sys.argv[2:]:
        piece, ref = arg.split(":")
        spec = json.load(open(os.path.join(track, "design", piece, "spec.json")))
        cv = spec["canvas"]
        md = os.path.join(track, "design", piece, "masks")
        prof = G.profile(ref)
        wall = np.asarray(Image.open(os.path.join(L, piece, "clean-wall.png")).convert("RGBA"))
        conc = mask(md, "wall", ["face_back", "face_head"], wall.shape[:2]) * (wall[..., 3] > 250)
        g = G.row_gains(wall, conc, cv["y0"], cv["ppw"], prof, world_x0=cv["x0"], xr=G.wall_x(ref))
        gw = G.gains_to_world(g, cv["y0"], cv["ppw"])
        gw = G.with_feedback(ref, gw)  # fix round 2: closed on the last render.sh pass (feedback.py)
        meds = G.row_medians(wall, conc, cv["y0"], cv["ppw"])
        beyond = np.asarray(Image.open(os.path.join(L, piece, "clean-beyond.png")).convert("RGBA"))
        bm = mask(md, "beyond", ["back_wall"], beyond.shape[:2]) * (beyond[..., 3] > 250)
        gb = G.gains_to_world(G.row_gains(beyond, bm, cv["y0"], cv["ppw"], prof, ratio=G.PASSAGE_RATIO), cv["y0"], cv["ppw"])
        bmeds = G.row_medians(beyond, bm, cv["y0"], cv["ppw"])
        os.makedirs(os.path.join(OUT, piece), exist_ok=True)
        for layer, gg, keepn, mm in (("wall", gw, ["light_diffuser"], meds), ("front", gw, [], meds), ("beyond", gb, ["light_diffuser"], bmeds)):
            im = np.asarray(Image.open(os.path.join(L, piece, f"clean-{layer}.png")).convert("RGBA"))
            keep = mask(md, layer, keepn, im.shape[:2]) if keepn else None
            out = G.apply_world_gains(im, cv["y0"], cv["ppw"], gg, keep, mm)
            if layer == "beyond":
                # fix round 2 (human: "a stray white dash with no fitting"): the batten behind the doorway
                # reads as a lamp: body and clips at their painted value, lens at half the darkening, a soft
                # pool on the wall round it (grade2.fitting_pool)
                lens = mask(md, "beyond", ["light_diffuser"], im.shape[:2])
                body = mask(md, "beyond", ["light_body", "light_cap0", "light_cap1", "light_clip0", "light_clip1"], im.shape[:2])
                if lens.max() > 0:
                    out = G.fitting_pool(im, cv["y0"], cv["ppw"], gg, None, lens, body, meds=mm)
                    out = batten_r3(out, md, im.shape[:2])
            if layer == "wall":
                # the exit sign hangs out in the room under its own conduit-fed lamp: it takes only half
                # the wall's darkening (the square root of its gain), so its housing reads round the legend
                sign = mask(md, "wall", ["sign_housing", "sign_face", "sign_bracket", "sign_wallplate"], im.shape[:2])
                if sign.max() > 0:
                    half = G.apply_world_gains(im, cv["y0"], cv["ppw"], (gg[0], np.sqrt(gg[1])), keep)  # (linear gain, square root)
                    out = np.where(sign[..., None] > 0.5, half, out)
            cm = {"wall": conc, "front": mask(md, "front", ["col_face", "col_end", "stub_face", "stub_top"], im.shape[:2]), "beyond": bm}.get(layer)
            if layer == "beyond":
                # fix round 3 (human r3, the white dashes): the passage wall's mask runs on behind its batten,
                # and the detail lift (a log-luminance unsharp mask) drove the diffuser, far brighter than the
                # wall round it, to 255 (this, not its grade, was round 2's "white dash"); the fitting is left out
                fit = mask(md, "beyond", ["light_diffuser", "light_body", "light_cap0", "light_cap1", "light_clip0", "light_clip1", "light_conduit"], im.shape[:2])
                cm = cm * (ndimage.binary_dilation(fit > 0.5, iterations=6) == 0)
            if cm is not None:
                out = G.boost_detail(out, cm, ppw=cv["ppw"])
            Image.fromarray(out, "RGBA").save(os.path.join(OUT, piece, f"clean-{layer}.png"))
        lg = G.median_gain(gw, 352.0, 436.0)
        leaf_gains.append(lg)
        report[piece] = {"ref": ref, "leaf_rows_gain": round(lg, 3),
                         "wall_gain_by_world_y": {str(int(y)): round(float(v), 3) for y, v in zip(gw[0][::40], gw[1][::40])},
                         "passage_gain_by_world_y": {str(int(y)): round(float(v), 3) for y, v in zip(gb[0][::40], gb[1][::40])}}
    # fix round 2 (N3): the leaf faces are copied as cleaned; their level is the SwingLeaf's runtime light
    # times the door end's one exposure (placement.json "exposure"), set from the render so the painted
    # steel sits at LEAF_FRAC x the concrete beside it (measure_leaf.py), not by a texture gain here
    os.makedirs(os.path.join(OUT, "leaf"), exist_ok=True)
    lmd = os.path.join(track, "design", "leaf", "masks")
    for f in os.listdir(os.path.join(L, "leaf")):
        im = np.asarray(Image.open(os.path.join(L, "leaf", f)).convert("RGBA"))
        face = f[len("clean-"):-4]
        if face != "edge":
            # fix round 2 (checklist item 9): the paint's even white flecks calmed, scuffs and grime kept
            plate = mask(lmd, face, ["leaf", "kick"], im.shape[:2]) * (im[..., 3] > 0)
            im = G.despeckle(im, plate)
            if face == "room":
                # fix round 2 (S1): the room face's lever, rose and thumbturn read at play size as worn steel
                # catching the door light (as the outside faces' do), not as grey on grey
                hw = mask(lmd, face, ["lever", "rose", "thumbturn", "thumbturn_rose"], im.shape[:2])
                if hw.max() > 0:
                    im = np.where(hw[..., None] > 0.5, G.scale_lin(im, 2.4), im)
            # fix round 3 (review r3 R3-2): wear where use and water put it, and the grain lifted (leafwear.py)
            seed = {"room": 11, "out-exit": 12, "out-entry": 13}[face] + (100 if os.path.basename(track) == "jentry" else 0)
            im = LW.apply(im, face, mask(lmd, face, ["lever"], im.shape[:2]), seed, plate=plate, lift=mask(lmd, face, ["leaf"], im.shape[:2]) * (im[..., 3] > 0),
                         grain=LW.JENTRY_GRAIN if os.path.basename(track) == "jentry" else (None, None))
        Image.fromarray(im.astype(np.uint8), "RGBA").save(os.path.join(OUT, "leaf", f))
    report["leaf_gain"] = 1.0
    if os.path.isdir(os.path.join(L, "container")):
        # fix round 2 (S6): the security container in the room's light, linear: lit from the room's ceiling
        # fitting in front of and above it, so its top and the upper front take the light and the front
        # falls off toward the base (to 0.45 at the plinth); its median set to CONTAINER_FRAC x the graded
        # exit wall at the same rows (grey enamel steel, never lighter than the concrete behind it)
        os.makedirs(os.path.join(OUT, "container"), exist_ok=True)
        ex = np.asarray(Image.open(os.path.join(OUT, "exit", "clean-wall.png")).convert("RGBA"))
        exspec = json.load(open(os.path.join(track, "design", "exit", "spec.json")))["canvas"]
        exm = mask(os.path.join(track, "design", "exit", "masks"), "wall", ["face_back"], ex.shape[:2])
        rows = exspec["y0"] + (np.arange(ex.shape[0]) + 0.5) / exspec["ppw"]
        exm = exm * ((rows >= 360.0) & (rows <= 430.0))[:, None]
        wall_med = G.masked_median(ex, exm)
        for f in os.listdir(os.path.join(L, "container")):
            im = np.asarray(Image.open(os.path.join(L, "container", f)).convert("RGBA"))
            h = im.shape[0]
            ramp = np.linspace(1.0, 0.45, h)[:, None]
            lin = G.to_lin(im) * ramp[..., None]
            tmp = im.copy(); tmp[..., :3] = G.to_srgb8(lin)
            cm = G.masked_median(tmp, (im[..., 3] > 250).astype(float))
            k = CONTAINER_FRAC * wall_med / max(cm, 1e-5)
            out = im.copy(); out[..., :3] = G.to_srgb8(lin * k)
            Image.fromarray(out, "RGBA").save(os.path.join(OUT, "container", f))
            report["container"] = {"wall_med": round(wall_med, 5), "before": round(cm, 5), "gain_lin": round(k, 3)}
    json.dump(report, open(os.path.join(OUT, "gains.json"), "w"), indent=1)
    print(json.dumps({k: (v.get("leaf_rows_gain", v) if isinstance(v, dict) else v) for k, v in report.items()}))


if __name__ == "__main__":
    main()
