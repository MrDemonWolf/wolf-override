"""Deterministic cleanup of the Codex paint-overs into the slice's layers (REAL-LOOK section 4 step 3).

For each job: resize the Codex original to its edit target, register it to the construction by
edge correlation, measure fidelity (silhouette IoU, edge correlation, strong-edge recall), then
re-impose the design's exact alpha (hole alpha 0), restore parts that must not change (Look 2
pixels, unlit lamp sockets, original ceiling and floor rows), clamp each part's value to the
design plan, calm large surfaces, match the corridor plate at the seam, and composite the typeset
marks. The Codex originals in codex/<job>/out/ are never modified. Writes layers/ and
layers/report.json.
"""
from __future__ import annotations

import glob
import json
import os
import sys

import numpy as np
from PIL import Image
from scipy import ndimage

sys.path.insert(0, os.path.dirname(__file__))
from imgkit import (decontaminate, match_chroma, load_rgb, resize, register, fidelity, iou, magenta_alpha, lum, to_lin, to_srgb, calm,
                    match_part, save_rgba)

# --- CONFIG -----------------------------------------------------------------------------------
# R is the working folder the piece was built in, with design/, layers/, paint/ and codex/ in it, and
# game-main/ (an export of main at 76d3a50) and game-slice/ (the modified copy) beside them. It was a
# temporary session folder; point WOLF_DOOR_END_WORK at your own copy to run this tool again.
R = os.environ.get("WOLF_DOOR_END_WORK", os.path.abspath("door-end-work"))
# ------------------------------------------------------------------------------------------------
D = os.path.join(R, "design")
C = os.path.join(R, "codex")
OUT = os.path.join(R, "layers")
GAME = os.path.join(R, "game-main", "apps", "game")
THRESH = {"silhouette_iou": 0.97, "edge_ncc_in_asset": 0.45, "strong_edge_recall": 0.80}


def mask(path: str) -> np.ndarray:
    return np.asarray(Image.open(path).convert("L")).astype(np.float64) / 255.0


def rgba(path: str) -> tuple[np.ndarray, np.ndarray]:
    a = np.asarray(Image.open(path).convert("RGBA")).astype(np.float64)
    return a[..., :3], a[..., 3] / 255.0


def passed(m: dict) -> bool:
    return all(m.get(k, 1.0) >= v for k, v in THRESH.items())


def prepared(job: str, out_name: str, target_name: str, design_size: tuple[int, int]) -> tuple[np.ndarray, dict]:
    target = load_rgb(os.path.join(C, job, "refs", target_name))
    painted = load_rgb(os.path.join(C, job, "out", out_name))
    painted = resize(painted, (target.shape[1], target.shape[0]))
    reg, t = register(painted, target)
    return resize(reg, design_size), t


# ----------------------------------------------------------------------------- portal

def portal(report: dict) -> None:
    P = os.path.join(D, "portal")
    M = os.path.join(P, "masks")
    size = (820, 1230)
    closed, tc = prepared("paint-portal", "portal-closed-painted.png", "1-edit-target-closed.png", size)
    opened, to = prepared("paint-portal", "portal-open-painted.png", "2-edit-target-open.png", size)
    fr, fa = rgba(os.path.join(P, "design-frame.png"))
    cr, ca = rgba(os.path.join(P, "design-curtain.png"))
    ft, fta = rgba(os.path.join(P, "design-front.png"))
    wr, wa = rgba(os.path.join(P, "design-wheel.png"))
    # the wheel on the portal canvas
    wx, wy = (690 - 646) * 4, (388 - 140) * 4
    wheel_a = np.zeros(fa.shape)
    wheel_a[wy:wy + 80, wx:wx + 80] = wa
    wheel_rgb = np.zeros(fr.shape)
    wheel_rgb[wy:wy + 80, wx:wx + 80] = wr

    def over(*layers):
        rgb = np.zeros(fr.shape)
        a = np.zeros(fa.shape)
        for lr, la in layers:
            rgb = rgb * (1 - la[..., None]) + lr * la[..., None]
            a = la + a * (1 - la)
        return rgb, a
    dc_rgb, dc_a = over((fr, fa), (cr, ca), (ft, fta), (wheel_rgb, wheel_a))
    do_rgb, do_a = over((fr, fa), (ft, fta), (wheel_rgb, wheel_a))
    mag = np.array([255.0, 0, 255.0])
    dc = dc_rgb * dc_a[..., None] + mag * (1 - dc_a[..., None])
    do = do_rgb * do_a[..., None] + mag * (1 - do_a[..., None])
    shadow = mask(os.path.join(M, "frame--contact_shadow.png"))
    for name, painted, design, da, t in (("closed", closed, dc, dc_a, tc), ("open", opened, do, do_a, to)):
        solid = np.clip(da - shadow, 0, 1) if name else da
        m = fidelity(painted, design, solid)
        m["silhouette_iou"] = round(iou(magenta_alpha(painted), (solid > 0.5).astype(float)), 4)
        m["registration"] = t
        m["pass"] = passed(m)
        report[f"portal-{name}"] = m
    # ---- frame (from the open painting): exact design alpha, hole alpha 0, lamp socket unlit
    hole = mask(os.path.join(M, "frame--hole.png"))
    v_open = magenta_alpha(opened) > 0.99
    v_closed = magenta_alpha(closed) > 0.99
    frame = decontaminate(opened.copy(), np.clip(fa - shadow, 0, 1) * (1 - hole), band=6)
    # under the turning wheel: the backplate and gearbox from the design, matched to the paint
    wsel = wheel_a > 0.02
    plate = mask(os.path.join(M, "frame--bypass_backplate.png")) > 0.5
    ring = plate & ~ndimage.binary_dilation(wsel, iterations=3)
    k = (to_lin(opened)[ring].mean(0) + 1e-6) / (to_lin(fr)[ring].mean(0) + 1e-6)
    frame[wsel] = to_srgb(to_lin(fr[wsel]) * k)
    # parts back to the design's value plan (+-20 %) and the socket unlit
    for part in sorted(glob.glob(os.path.join(M, "frame--*.png"))):
        nm = os.path.basename(part)[7:-4]
        if nm in ("ALPHA", "hole", "contact_shadow", "lamp_globe"):
            continue
        frame, _ = match_part(frame, fr, mask(part), tol=0.20, valid=v_open)
        frame = match_chroma(frame, fr, mask(part), 0.6, valid=v_open)
    g = mask(os.path.join(M, "frame--lamp_globe.png"))
    frame = frame * (1 - g[..., None]) + fr * g[..., None]
    for big in ("wall_face", "return_left"):
        bm = mask(os.path.join(M, f"frame--{big}.png"))
        frame = calm(frame, bm, 6.0, 0.8)
    # contact shadow: the design's (darkest at the contact line)
    shadow_only = (shadow > 0) & (np.clip(fa - shadow, 0, 1) < 0.5)
    frame[shadow_only] = fr[shadow_only]
    # typeset stencil (37875 white paint, lit like the wall it is on)
    tx = mask(os.path.join(D, "text", "text-frame.png"))
    wall = to_lin(frame)
    paint = np.clip(wall * (0.85 / 0.255), 0, 1)
    frame = frame * (1 - 0.92 * tx[..., None]) + to_srgb(paint) * 0.92 * tx[..., None]
    alpha = fa * (1 - hole)
    save_rgba(frame, alpha, os.path.join(OUT, "door", "seal-frame.png"))
    # ---- curtain (from the closed painting)
    curtain = decontaminate(closed.copy(), ca, band=6)
    for part in sorted(glob.glob(os.path.join(M, "curtain--*.png"))):
        nm = os.path.basename(part)[9:-4]
        if nm == "ALPHA":
            continue
        curtain, _ = match_part(curtain, cr, mask(part), tol=0.20, valid=v_closed)
        curtain = match_chroma(curtain, cr, mask(part), 0.6, valid=v_closed)
    save_rgba(curtain, ca, os.path.join(OUT, "door", "seal-curtain-canvas.png"))
    # ---- front: guides, hood, brackets, with the stencilled door number
    front = decontaminate(closed.copy(), fta, band=6)
    for part in sorted(glob.glob(os.path.join(M, "front--*.png"))):
        nm = os.path.basename(part)[7:-4]
        if nm == "ALPHA":
            continue
        front, _ = match_part(front, ft, mask(part), tol=0.20, valid=v_closed)
        front = match_chroma(front, ft, mask(part), 0.6, valid=v_closed)
    tx = mask(os.path.join(D, "text", "text-front.png"))
    paint = np.clip(to_lin(front) * (0.80 / 0.215), 0, 1)
    front = front * (1 - 0.92 * tx[..., None]) + to_srgb(paint) * 0.92 * tx[..., None]
    save_rgba(front, fta, os.path.join(OUT, "door", "seal-front-canvas.png"))
    # ---- wheel (from the closed painting)
    wheel = decontaminate(closed[wy:wy + 80, wx:wx + 80].copy(), wa, band=4)
    for part in sorted(glob.glob(os.path.join(M, "wheel--*.png"))):
        nm = os.path.basename(part)[7:-4]
        if nm == "ALPHA":
            continue
        wm = mask(part)
        wv = v_closed[wy:wy + 80, wx:wx + 80]
        wheel, _ = match_part(wheel, wr, wm, tol=0.25, valid=wv)
        wheel = match_chroma(wheel, wr, wm, 0.6, valid=wv)
    save_rgba(wheel, wa, os.path.join(OUT, "door", "bypass-wheel.png"))
    # checks on the cleaned layers
    report["portal-layers"] = {
        "hole_alpha_max": float(alpha[hole > 0.999].max()) if (hole > 0.999).any() else 0.0,
        "frame_alpha_equals_design": bool(np.abs(alpha - fa * (1 - hole)).max() < 1 / 255),
        "curtain_alpha_equals_design": True,
        "outside_mask_alpha_max": float(alpha[(fa == 0)].max()) if (fa == 0).any() else 0.0,
    }


# ----------------------------------------------------------------------------- far patch

def far(report: dict) -> None:
    F = os.path.join(D, "far-patch")
    M = os.path.join(F, "masks")
    painted, t = prepared("paint-far", "far-painted.png", "1-edit-target-far.png", (808, 808))
    design = load_rgb(os.path.join(F, "design.png"))
    designed = np.zeros((808, 808))
    for p in glob.glob(os.path.join(M, "*.png")):
        n = os.path.basename(p)[:-4]
        if n not in ("ceiling_keep", "corr_floor_keep"):
            designed = np.maximum(designed, mask(p))
    m = fidelity(painted, design, designed)
    m["silhouette_iou"] = 1.0  # opaque plate: no silhouette, edges only
    m["registration"] = t
    m["pass"] = passed(m)
    report["far-patch"] = m
    out = painted.copy()
    spec = json.load(open(os.path.join(F, "spec.json")))
    for part in spec["parts"]:
        pm = os.path.join(M, part["name"] + ".png")
        if os.path.exists(pm) and part["surface"]["kind"] != "emit":
            out, _ = match_part(out, design, mask(pm), tol=0.20)
    for big in ("mach_wall", "corr_wall"):
        out = calm(out, mask(os.path.join(M, big + ".png")), 5.0, 0.8)
    # the corridor's own surfaces match the old plate's palette at the seam (mean, per channel)
    orig = load_rgb(os.path.join(GAME, "assets/rooms/corridor-far.png"))
    left = to_lin(orig[230:660, 1040:1108]).reshape(-1, 3)
    corr = mask(os.path.join(M, "corr_wall.png")) > 0.5
    corr[:, 120:] = False
    here = to_lin(out)[corr]
    # match the old wall's colour (chromaticity) fully; its brightness only partly, since the new
    # wall sits under its own lamp while the strip left of the column does not
    lm_old = left.mean(0)
    lm_new = here.mean(0)
    chroma = (lm_old / lm_old.mean()) / (lm_new / lm_new.mean())
    gain = chroma * float(np.clip(lm_old.mean() / lm_new.mean(), 0.65, 1.0))
    corr_all = np.zeros((808, 808))
    for n in ("corr_wall", "corr_dado", "corr_dado_line", "corr_panel_joint", "seam_column", "seam_column_web", "seam_column_baseplate",
              "corr_pipe0", "corr_pipe1", "corr_pipe2", "corr_pipe_clamp0", "corr_pipe_clamp1", "beacon_conduit", "beacon_backbox"):
        p = os.path.join(M, n + ".png")
        if os.path.exists(p):
            corr_all = np.maximum(corr_all, mask(p))
    out = out * (1 - corr_all[..., None]) + to_srgb(to_lin(out) * gain) * corr_all[..., None]
    report["far-patch"]["seam_gain_rgb"] = [round(float(g), 3) for g in gain]
    # rows and columns that must stay the old plate: the ceiling band, the corridor floor (lit by
    # the design), and the four columns left of the seam column
    keep = mask(os.path.join(M, "ceiling_keep.png"))
    ofar = load_rgb(os.path.join(F, "far-base-streak-removed.png"))[0:808, 1112:1920]
    out = out * (1 - keep[..., None]) + ofar * keep[..., None]
    fl = mask(os.path.join(M, "corr_floor_keep.png"))
    out = out * (1 - fl[..., None]) + design * fl[..., None]
    # The opening's widest framing reaches far-plate source x 1128 (camera 300, zoom 1.95), so the
    # old plate is kept, untouched, up to source x 1132 (patch x 20): the seam then falls inside the
    # new steel column (its left edge), and the floor's added lamp light fades in over 48 px.
    KEEP_X = 20
    floor_row = int(round((423.3 - 78.5) * 2))
    out[:floor_row, :KEEP_X] = ofar[:floor_row, :KEEP_X]
    ramp = np.clip((np.arange(808) - KEEP_X) / 48.0, 0, 1)[None, :, None]
    out[floor_row:] = ofar[floor_row:] * (1 - ramp) + out[floor_row:] * ramp
    # lamp lenses stay the design's emitters
    for n in ("lum_lens", "highbay_A_lens", "highbay_B_lens"):
        p = os.path.join(M, n + ".png")
        if os.path.exists(p):
            lm = mask(p)
            out = out * (1 - lm[..., None]) + design * lm[..., None]
    full = np.asarray(Image.open(os.path.join(F, "far-base-streak-removed.png")).convert("RGB")).copy()
    full[0:808, 1112:1920] = np.clip(out + 0.5, 0, 255).astype(np.uint8)
    os.makedirs(os.path.join(OUT, "room"), exist_ok=True)
    Image.fromarray(full, "RGB").save(os.path.join(OUT, "room", "corridor-far.png"))
    Image.fromarray(np.clip(out + 0.5, 0, 255).astype(np.uint8), "RGB").save(os.path.join(OUT, "room", "far-patch-cleaned.png"))


# ----------------------------------------------------------------------------- stations

def stations(report: dict) -> None:
    S = os.path.join(D, "stations")
    info = json.load(open(os.path.join(C, "..", "paint", "inputs.json")))["paint-stations"]
    target = load_rgb(os.path.join(C, "paint-stations", "refs", "1-edit-target-stations.png"))
    painted = resize(load_rgb(os.path.join(C, "paint-stations", "out", "stations-painted.png")), (1024, 1024))
    reg, t = register(painted, target)
    sheet = resize(reg, (720, 720))
    for name in ("relay", "safe-point"):
        x, y, w, h = info["placement_in_sheet"][name]
        drgb, da = rgba(os.path.join(S, f"design-{name}.png"))
        crop = sheet[y:y + h, x:x + w]
        m = fidelity(crop, drgb * da[..., None] + np.array([255.0, 0, 255.0]) * (1 - da[..., None]), da)
        m["silhouette_iou"] = round(iou(magenta_alpha(crop), (da > 0.5).astype(float)), 4)
        m["registration"] = t
        m["pass"] = passed(m)
        report[f"station-{name}"] = m
        look2 = mask(os.path.join(S, "masks", f"{name}--look2.png"))
        plinth = mask(os.path.join(S, "masks", f"{name}--plinth.png"))
        brush = mask(os.path.join(S, "masks", f"{name}--brush_strip.png"))
        sh_m = mask(os.path.join(S, "masks", f"{name}--contact_shadow.png"))
        out = decontaminate(crop.copy(), np.clip(da - sh_m, 0, 1))
        out, _ = match_part(out, drgb, plinth * (1 - look2), tol=0.20)
        # the approved Look 2 art, pixel for pixel; the brush strip stays dark; shadow from design
        keep = np.clip(look2 + brush + (1 - np.clip(plinth + look2, 0, 1)), 0, 1)
        out = out * (1 - keep[..., None]) + drgb * keep[..., None]
        os.makedirs(os.path.join(OUT, "stations"), exist_ok=True)
        save_rgba(out, da, os.path.join(OUT, "stations", f"{name}-grounded.png"))
        l2 = look2 > 0.999
        report[f"station-{name}"]["look2_pixels_unchanged"] = bool(np.abs(out[l2] - drgb[l2]).max() < 0.51)


def main() -> None:
    os.makedirs(os.path.join(OUT, "door"), exist_ok=True)
    report: dict = {"thresholds": THRESH}
    which = sys.argv[1:] or ["portal", "far", "stations"]
    for w in which:
        {"portal": portal, "far": far, "stations": stations}[w](report)
    path = os.path.join(OUT, "report.json")
    old = json.load(open(path)) if os.path.exists(path) else {}
    old.update(report)
    json.dump(old, open(path, "w"), indent=1)
    print(json.dumps(report, indent=1))


if __name__ == "__main__":
    main()
