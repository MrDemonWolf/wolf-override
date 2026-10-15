"""Records doors: deterministic cleanup of the Codex paint (doors-r1, records track). Scratch only.

For every piece the construction design rules and Codex supplies only surface material:
  1. the painted image is mapped back onto the design canvas (layout.json);
  2. each part's own pixels (the topmost part owns a pixel) take the design's colour and light, times
     the paint's local material detail: its luminance over its own part-masked blur (sigma 5 px),
     clamped to +-35 % (sigma 12 px) (calm surfaces; no paint-on light, glow or shadow survives);
  3. alpha is the design's alpha exactly (silhouettes snap back; the doorway, the lamp glass and every
     opening stay alpha 0); the contact shadows are composited from the design's footprints;
  4. one exposure per door end sets the cross-wall face to an average between the Records back wall
     it meets and the room's pillars (sampled from a main capture), and the piece takes half the room's
     cool cast;
  5. checks: silhouette match 100 %, no alpha in a hole, nothing outside the design alpha.
Writes layers/<piece>/clean-<layer>.png at the design's 4 px per world px, and layers/report.json.
"""
from __future__ import annotations

import json
import os
import sys

import numpy as np
from PIL import Image
from scipy import ndimage

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import rmodel as M  # noqa: E402
import rdesign as RD  # noqa: E402

CODEX = os.path.join(M.TRACK, "..", "codex")
LAYERS = os.path.join(M.TRACK, "layers")
# the Codex jobs whose paint is used (v2: re-painted after the container moved to x 797, behind the walk line)
JOBS = {"exit": "records-exit-v2", "entry": "records-entry", "parts": "records-parts-v2"}
SIGMA = 12.0
DETAIL = 0.35
FACE_TARGET_LUM = 0.034  # the cross-wall face averages about sRGB 52, between the Records back wall (42-66) and its pillars (35)


def lum(lin):
    return lin[..., 0] * 0.2126 + lin[..., 1] * 0.7152 + lin[..., 2] * 0.0722


def load_mask(path):
    return np.asarray(Image.open(path), dtype=np.float64) / 255.0


def owners(names, mask_dir, prefix):
    """Index of the topmost part per pixel (-1 where none reaches 0.5 coverage)."""
    own = None
    for i, n in enumerate(names):
        p = os.path.join(mask_dir, f"{prefix}--{n}.png")
        if not os.path.exists(p):
            continue
        m = load_mask(p)
        if own is None:
            own = np.full(m.shape, -1, int)
        own = np.where(m >= 0.5, i, own)
    return own


def detail_map(painted_lin, own, n_parts, sigma=SIGMA):
    L = np.maximum(lum(painted_lin), 1e-4)
    logL = np.log(L)
    out = np.zeros_like(L)
    for i in range(n_parts):
        m = (own == i).astype(np.float64)
        if m.sum() < 4:
            continue
        num = ndimage.gaussian_filter(logL * m, sigma)
        den = ndimage.gaussian_filter(m, sigma)
        base = num / np.maximum(den, 1e-6)
        out = np.where(m > 0, logL - base, out)
    return np.exp(np.clip(out, -DETAIL, DETAIL))


def clean_layer(design_png, mask_dir, layer, part_names, painted_lin, exposure=1.0, cast=(1.0, 1.0, 1.0), extra_detail_ok=()):
    des = np.asarray(Image.open(design_png).convert("RGBA")).astype(np.float64)
    alpha_full = des[..., 3] / 255.0
    body_a = load_mask(os.path.join(mask_dir, f"{layer}--ALPHA.png"))
    sh_p = os.path.join(mask_dir, f"{layer}--contact_shadow.png")
    shadow = load_mask(sh_p) if os.path.exists(sh_p) else np.zeros_like(body_a)
    # the design's lit colour of the body (undo the shadow composite: where the body is opaque the
    # composite is the body's own colour)
    d_lin = M.from_srgb_u8(des[..., :3].astype(np.uint8))
    own = owners(part_names, mask_dir, layer)
    det = detail_map(painted_lin, own, len(part_names))
    out_lin = d_lin * det[..., None] * exposure * np.array(cast)
    rgb = M.to_srgb_u8(out_lin)
    # re-composite the contact shadow under the body (near-black at the shadow's alpha)
    a = body_a + shadow * (1 - body_a)
    rgb = (rgb.astype(np.float64) * (body_a / np.maximum(a, 1e-6))[..., None] + 6.0 * (shadow * (1 - body_a) / np.maximum(a, 1e-6))[..., None])
    rgba = np.dstack([np.clip(rgb, 0, 255).astype(np.uint8), (a * 255 + 0.5).astype(np.uint8)])
    checks = {
        "silhouette_match": float(((rgba[..., 3] > 127) == (alpha_full > 0.5)).mean()),
        "outside_design_alpha_px": int(((rgba[..., 3] > 0) & (alpha_full <= 0.0)).sum()),
        "detail_log_range": [float(np.log(det).min()), float(np.log(det).max())],
    }
    return rgba, checks


def painted_on_design_canvas(job, cv):
    lay = json.load(open(os.path.join(CODEX, job, "layout.json")))
    im = Image.open([os.path.join(CODEX, job, "out", f) for f in os.listdir(os.path.join(CODEX, job, "out")) if f.endswith(".png")][0]).convert("RGB")
    # world rect of the target -> painted pixels; sample at the design canvas's pixel centres
    X0, Y0, Wd, Hd = lay["world_x0"], lay["world_y0"], lay["world_w"], lay["world_h"]
    sx = im.size[0] / Wd
    sy = im.size[1] / Hd
    # crop the world rect of the design canvas and resize to it
    left = (cv["x0"] - X0) * sx
    top = (cv["y0"] - Y0) * sy
    right = left + cv["w"] / cv["ppw"] * sx
    bottom = top + cv["h"] / cv["ppw"] * sy
    crop = im.transform((cv["w"], cv["h"]), Image.Transform.EXTENT, (left, top, right, bottom), Image.Resampling.BICUBIC)
    return M.from_srgb_u8(np.asarray(crop))


def far_wall_reference(side):
    """Mean luminance of the Records back wall where the cross-wall meets it (the far plate at the
    clamp), so the cross-wall is set a step brighter than the wall behind it."""
    far = np.asarray(Image.open(os.path.join(M.TRACK, "..", "main-records", "apps", "game", "assets", "rooms", "records-far.png")).convert("RGB"))
    shift = RD.FAR_SHIFT_RIGHT if side > 0 else RD.FAR_SHIFT_LEFT
    xs = (700.0, 785.0) if side > 0 else (165.0, 250.0)
    sx0, sx1 = int((xs[0] - shift) * 2), int((xs[1] - shift) * 2)
    sy0, sy1 = int((250 - 69) * 2), int((400 - 69) * 2)
    return float(lum(M.from_srgb_u8(far[sy0:sy1, sx0:sx1])).mean()), M.from_srgb_u8(far[sy0:sy1, sx0:sx1]).reshape(-1, 3).mean(0)


def main():
    report = {}
    for side in (1, -1):
        piece = "exit" if side > 0 else "entry"
        job = JOBS[piece]
        spec = json.load(open(os.path.join(M.DESIGN, piece, "spec.json")))
        cv = spec["canvas"]
        painted = painted_on_design_canvas(job, cv)
        mask_dir = os.path.join(M.DESIGN, piece, "masks")
        out = os.path.join(LAYERS, piece)
        os.makedirs(out, exist_ok=True)
        ref_l, ref_rgb = far_wall_reference(side)
        # the cross-wall's design luminance over its big face
        own_face = load_mask(os.path.join(mask_dir, "wall--face_back.png")) > 0.5
        d_wall = M.from_srgb_u8(np.asarray(Image.open(os.path.join(M.DESIGN, piece, "design-wall.png")).convert("RGB")))
        face_l = float(lum(d_wall)[own_face].mean())
        exposure = float(np.clip(FACE_TARGET_LUM / max(face_l, 1e-6), 0.6, 3.0))
        cast_raw = ref_rgb / max(ref_rgb.mean(), 1e-6)
        cast = tuple(float(c) for c in (0.55 + 0.45 * cast_raw))  # half-way to the room's cool cast
        rep = {"exposure": exposure, "cast": cast, "far_wall_lum": ref_l, "design_face_lum": face_l}
        for layer in ("wall", "front", "beyond"):
            names = [p["name"] for p in spec["parts"] if p["layer"] == layer]
            if layer == "front":
                names = names + ["GLASS_HOLE"]
            rgba, checks = clean_layer(os.path.join(M.DESIGN, piece, f"design-{layer}.png"), mask_dir, layer, names, painted, exposure, cast)
            if layer == "front":
                glass = load_mask(os.path.join(mask_dir, "front--GLASS_HOLE.png"))
                rgba[..., 3] = np.where(glass > 0.5, 0, rgba[..., 3])
                checks["glass_hole_alpha_px"] = int(((glass > 0.5) & (rgba[..., 3] > 0)).sum())
            Image.fromarray(rgba, "RGBA").save(os.path.join(out, f"clean-{layer}.png"))
            rep[layer] = checks
        report[piece] = rep
    # the parts sheet: leaf faces, edge, container
    lay = json.load(open(os.path.join(CODEX, JOBS["parts"], "layout.json")))
    im = Image.open([os.path.join(CODEX, JOBS["parts"], "out", f) for f in os.listdir(os.path.join(CODEX, JOBS["parts"], "out")) if f.endswith(".png")][0]).convert("RGB")
    k = im.size[0] / lay["target"][0]
    out = os.path.join(LAYERS, "leaf")
    os.makedirs(out, exist_ok=True)
    leaf_spec = json.load(open(os.path.join(M.DESIGN, "leaf", "spec.json")))
    rep = {}
    for name in ("room", "out-exit", "out-entry", "edge"):
        it = lay["items"][name]
        w, h = it["size"]
        x, y = it["xy"]
        box = (x * k, y * k, (x + w * it["scale"]) * k, (y + h * it["scale"]) * k)
        crop = im.transform((w, h), Image.Transform.EXTENT, box, Image.Resampling.BICUBIC)
        p_lin = M.from_srgb_u8(np.asarray(crop))
        d_lin = M.from_srgb_u8(np.asarray(Image.open(os.path.join(M.DESIGN, "leaf", f"design-{name}.png")).convert("RGB")))
        names = [p["name"] for p in leaf_spec["faces"][name]["parts"]]
        if name == "edge":
            own = np.zeros(d_lin.shape[:2], int)
        else:
            own = owners(names, os.path.join(M.DESIGN, "leaf", "masks"), name)
            own = np.where(own < 0, 0, own)
        det = detail_map(p_lin, own, len(names), sigma=4.0)
        rgb = M.to_srgb_u8(d_lin * det[..., None])
        Image.fromarray(rgb).save(os.path.join(out, f"clean-{name}.png"))
        rep[name] = {"detail_log_range": [float(np.log(det).min()), float(np.log(det).max())]}
    report["leaf"] = rep
    # the container
    it = lay["items"]["container"]
    cs = json.load(open(os.path.join(M.DESIGN, "container", "spec.json")))
    w, h = it["size"]
    x, y = it["xy"]
    box = (x * k, y * k, (x + w * it["scale"]) * k, (y + h * it["scale"]) * k)
    crop = im.transform((w, h), Image.Transform.EXTENT, box, Image.Resampling.BICUBIC)
    p_lin = M.from_srgb_u8(np.asarray(crop))
    names = [p["name"] for p in cs["parts"]]
    ex = report["exit"]
    rgba, checks = clean_layer(os.path.join(M.DESIGN, "container", "design-container.png"), os.path.join(M.DESIGN, "container", "masks"), "container", names, p_lin, ex["exposure"], ex["cast"])
    os.makedirs(os.path.join(LAYERS, "container"), exist_ok=True)
    Image.fromarray(rgba, "RGBA").save(os.path.join(LAYERS, "container", "clean-container.png"))
    report["container"] = checks
    M.write_json(os.path.join(LAYERS, "report.json"), report)
    print(json.dumps(report, indent=1))


if __name__ == "__main__":
    main()
