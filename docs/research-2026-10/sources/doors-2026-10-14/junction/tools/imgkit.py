"""Registration, fidelity checks and mask re-imposition for the Codex paint-overs (scratch only)."""
from __future__ import annotations

import numpy as np
from PIL import Image
from scipy import ndimage

MAG = np.array([255.0, 0.0, 255.0])


def load_rgb(path: str) -> np.ndarray:
    return np.asarray(Image.open(path).convert("RGB")).astype(np.float64)


def resize(arr: np.ndarray, size: tuple[int, int]) -> np.ndarray:
    """size = (w, h); float RGB/L array resampled with Lanczos (per channel through PIL 'F')."""
    if arr.ndim == 2:
        return np.asarray(Image.fromarray(arr.astype(np.float32), "F").resize(size, Image.Resampling.LANCZOS)).astype(np.float64)
    return np.stack([resize(arr[..., c], size) for c in range(arr.shape[2])], -1)


def lum(rgb: np.ndarray) -> np.ndarray:
    return rgb[..., 0] * 0.2126 + rgb[..., 1] * 0.7152 + rgb[..., 2] * 0.0722


def grad(l: np.ndarray, sigma: float = 1.0) -> np.ndarray:
    g = ndimage.gaussian_filter(l, sigma)
    return np.hypot(ndimage.sobel(g, 0), ndimage.sobel(g, 1))


def magenta_alpha(rgb: np.ndarray) -> np.ndarray:
    """1 where a pixel is not the flat key, 0 on #FF00FF (soft over a small distance)."""
    d = np.sqrt(((rgb - MAG) ** 2).sum(-1))
    return np.clip((d - 40.0) / 60.0, 0, 1)


def warp(arr: np.ndarray, scale: float, dx: float, dy: float) -> np.ndarray:
    """Output pixel p samples input at (p - c) / scale + c - (dx, dy) about the centre c."""
    h, w = arr.shape[:2]
    cy, cx = (h - 1) / 2, (w - 1) / 2
    yy, xx = np.mgrid[0:h, 0:w].astype(np.float64)
    sy = (yy - cy) / scale + cy - dy
    sx = (xx - cx) / scale + cx - dx
    if arr.ndim == 2:
        return ndimage.map_coordinates(arr, [sy, sx], order=1, mode="nearest")
    return np.stack([ndimage.map_coordinates(arr[..., c], [sy, sx], order=1, mode="nearest") for c in range(arr.shape[2])], -1)


def ncc(a: np.ndarray, b: np.ndarray, m: np.ndarray | None = None) -> float:
    if m is None:
        m = np.ones_like(a)
    w = m / max(m.sum(), 1e-9)
    am = (a * w).sum()
    bm = (b * w).sum()
    va = (((a - am) ** 2) * w).sum()
    vb = (((b - bm) ** 2) * w).sum()
    return float((((a - am) * (b - bm)) * w).sum() / np.sqrt(max(va * vb, 1e-12)))


def register(painted: np.ndarray, target: np.ndarray, scales=np.linspace(0.97, 1.03, 13), shift=6) -> tuple[np.ndarray, dict]:
    """Aligns the painted image (already resized to the target's size) to the edit target by
    maximising the correlation of their edge maps over scale and an integer shift, then a
    half-pixel refinement. Returns the warped painted image and the transform."""
    gt = grad(lum(target), 1.5)
    gp0 = grad(lum(painted), 1.5)
    best = (-2.0, 1.0, 0.0, 0.0)
    for s in scales:
        gp = warp(gp0, s, 0, 0)
        for dy in range(-shift, shift + 1, 2):
            for dx in range(-shift, shift + 1, 2):
                v = ncc(np.roll(np.roll(gp, dy, 0), dx, 1)[shift:-shift, shift:-shift], gt[shift:-shift, shift:-shift])
                if v > best[0]:
                    best = (v, s, dx, dy)
    v, s, dx0, dy0 = best
    for dy in np.arange(dy0 - 1.5, dy0 + 1.6, 0.5):
        for dx in np.arange(dx0 - 1.5, dx0 + 1.6, 0.5):
            vv = ncc(warp(gp0, s, dx, dy)[shift:-shift, shift:-shift], gt[shift:-shift, shift:-shift])
            if vv > best[0]:
                best = (vv, s, dx, dy)
    v, s, dx, dy = best
    return warp(painted, s, dx, dy), {"edge_ncc": round(v, 4), "scale": round(float(s), 4), "dx": float(dx), "dy": float(dy)}


def fidelity(painted: np.ndarray, design: np.ndarray, alpha: np.ndarray) -> dict:
    """Edge fidelity (the painted edge map against the construction's, inside the asset) and edge
    recall (share of the construction's strong edges that have a painted edge within 1 px)."""
    m = (ndimage.binary_dilation(alpha > 0.5, iterations=2)).astype(float)
    gd = grad(lum(design), 1.0)
    gp = grad(lum(painted), 1.0)
    strong = (gd > np.percentile(gd[m > 0], 90)) & (m > 0)
    near = ndimage.maximum_filter(gp, size=3)
    recall = float((near[strong] > 0.35 * np.median(gd[strong])).mean()) if strong.any() else 1.0
    return {"edge_ncc_in_asset": round(ncc(gp, gd, m), 4), "strong_edge_recall": round(recall, 4)}


def iou(a: np.ndarray, b: np.ndarray) -> float:
    A, B = a > 0.5, b > 0.5
    return float((A & B).sum() / max((A | B).sum(), 1))


def to_lin(u8: np.ndarray) -> np.ndarray:
    c = np.clip(u8, 0, 255) / 255.0
    return np.where(c <= 0.04045, c / 12.92, ((c + 0.055) / 1.055) ** 2.4)


def to_srgb(lin: np.ndarray) -> np.ndarray:
    lin = np.clip(lin, 0, 1)
    return np.where(lin <= 0.0031308, lin * 12.92, 1.055 * lin ** (1 / 2.4) - 0.055) * 255.0


def calm(rgb: np.ndarray, mask: np.ndarray, sigma: float, keep: float) -> np.ndarray:
    """Calms a large surface: keeps its broad light and `keep` of its fine texture."""
    low = np.stack([ndimage.gaussian_filter(rgb[..., c], sigma) for c in range(3)], -1)
    out = low + keep * (rgb - low)
    return rgb * (1 - mask[..., None]) + out * mask[..., None]


def match_part(rgb: np.ndarray, design: np.ndarray, mask: np.ndarray, tol: float = 0.15, valid: np.ndarray | None = None) -> tuple[np.ndarray, float]:
    """Clamps a part's mean linear luminance to within `tol` of the design's value plan (key-coloured
    pixels, such as a doorway hole inside a wall's mask, are left out of the statistics: `valid`, taken
    from the untouched paint-over, since a darkened key colour no longer looks like the key)."""
    sel = (mask > 0.5) & (valid if valid is not None else magenta_alpha(rgb) > 0.99)
    if sel.sum() < 4:
        return rgb, 1.0
    lp = lum(to_lin(rgb))[sel].mean()
    ld = lum(to_lin(design))[sel].mean()
    if lp <= 1e-6:
        return rgb, 1.0
    r = ld / lp
    k = float(np.clip(r, 1 - tol, 1 + tol)) if False else 1.0
    lo, hi = ld * (1 - tol), ld * (1 + tol)
    target = np.clip(lp, lo, hi)
    k = target / lp
    if abs(k - 1) < 1e-6:
        return rgb, 1.0
    lin = to_lin(rgb) * k
    out = to_srgb(lin)
    return rgb * (1 - mask[..., None]) + out * mask[..., None], float(k)


def save_rgba(rgb: np.ndarray, alpha: np.ndarray, path: str) -> None:
    a = (np.clip(alpha, 0, 1) * 255 + 0.5).astype(np.uint8)
    c = np.clip(rgb + 0.5, 0, 255).astype(np.uint8)
    c[a == 0] = 0
    Image.fromarray(np.dstack([c, a]), "RGBA").save(path)


def decontaminate(rgb: np.ndarray, alpha: np.ndarray, band: int = 3) -> np.ndarray:
    """Replaces every pixel within `band` px of the silhouette (inside the asset, where the paint-over
    met the #FF00FF key) with the colour of the nearest interior pixel, so no key colour fringes."""
    interior = ndimage.binary_erosion(alpha >= 0.99, iterations=band)
    if not interior.any():
        return rgb
    _, (iy, ix) = ndimage.distance_transform_edt(~interior, return_indices=True)
    out = rgb.copy()
    edge = (alpha > 0) & ~interior
    out[edge] = rgb[iy[edge], ix[edge]]
    return out


def match_chroma(rgb: np.ndarray, design: np.ndarray, mask: np.ndarray, strength: float = 0.6, valid: np.ndarray | None = None) -> np.ndarray:
    """Moves a part's mean colour (chromaticity only, luminance kept) toward the design's, which
    carries the colour of the designed light sources. Key-coloured pixels (`valid`) are left out."""
    sel = (mask > 0.5) & (valid if valid is not None else magenta_alpha(rgb) > 0.99)
    if sel.sum() < 4:
        return rgb
    p = to_lin(rgb)[sel].mean(0) + 1e-6
    d = to_lin(design)[sel].mean(0) + 1e-6
    ratio = (d / d.mean()) / (p / p.mean())
    gain = ratio ** strength
    gain = gain / (gain * np.array([0.2126, 0.7152, 0.0722])).sum() * 1.0  # keep luminance
    out = to_srgb(to_lin(rgb) * gain)
    return rgb * (1 - mask[..., None]) + out * mask[..., None]
