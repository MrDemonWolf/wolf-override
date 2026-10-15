"""A small re-implementation of Godot 4's CPUParticles2D update and draw for the relief jet, to
design its parameters and make mock frames (the real check is the render.sh capture).

Follows cpu_particles_2d.cpp: ring-buffer emission (explosiveness 0: particle i starts at
i/amount of the lifetime), spread as a random angle in [-spread, spread], linear damping on the
speed, gravity, scale = scale_amount * scale_curve(t), ALIGN_Y (the texture's Y axis along the
velocity), colour = color * color_ramp(t), normal ('mix') blending, a radial GradientTexture2D.
"""
import json
import math

import numpy as np

P = {
    "amount": 16,
    "lifetime": 0.36,
    "direction": [0.0, 1.0],
    "spread": 5.0,
    "velocity": [62.0, 72.0],
    "damping": [55.0, 70.0],
    "gravity": [0.0, -10.0],
    "scale": [0.85, 1.0],
    "scale_curve": [[0.0, 0.2], [0.3, 0.55], [1.0, 1.15]],
    "texture": [10, 16],  # GradientTexture2D, radial, UV space (so an ellipse)
    "tex_offsets": [0.0, 0.45, 1.0],
    "tex_alpha": [1.0, 0.4, 0.0],
    "color": [0.84, 0.9, 0.93, 0.18],
    "ramp_offsets": [0.0, 0.12, 0.45, 1.0],
    "ramp_alpha": [0.8, 1.0, 0.45, 0.0],
}


def curve(points, t):
    xs = [p[0] for p in points]; ys = [p[1] for p in points]
    return float(np.interp(t, xs, ys))


def simulate(p, seconds=2.0, fps=60, seed=1):
    rng = np.random.default_rng(seed)
    n = p["amount"]; life = p["lifetime"]
    parts = [None] * n
    dt = 1.0 / fps
    t = 0.0
    frames = int(seconds * fps)
    for f in range(frames):
        t_new = t + dt
        for i in range(n):
            q = parts[i]
            if q is not None:
                q["age"] += dt
                _step(q, p, dt)
                if q["age"] >= life:
                    parts[i] = None
        # emission: particle i (re)starts each time the clock passes i/n of the lifetime
        for i in range(n):
            phase = i / n * life
            k_prev = math.floor((t - phase) / life) if t >= phase else -1
            k_new = math.floor((t_new - phase) / life) if t_new >= phase else -1
            if k_new > k_prev:
                start = phase + k_new * life
                ang = math.radians(rng.uniform(-p["spread"], p["spread"]))
                d = np.array(p["direction"], float); d /= np.linalg.norm(d)
                c, s = math.cos(ang), math.sin(ang)
                d = np.array([d[0] * c - d[1] * s, d[0] * s + d[1] * c])
                v = d * rng.uniform(*p["velocity"])
                parts[i] = {"pos": np.zeros(2), "vel": v, "age": t_new - start,
                            "damp": rng.uniform(*p["damping"]), "scale": rng.uniform(*p["scale"])}
                _step(parts[i], p, parts[i]["age"])
        t = t_new
    return [q for q in parts if q is not None and q["age"] < life]


def _step(q, p, dt):
    q["vel"] = q["vel"] + np.array(p["gravity"]) * dt
    sp = np.linalg.norm(q["vel"])
    if sp > 0:
        sp2 = max(0.0, sp - q["damp"] * dt)
        q["vel"] = q["vel"] / sp * sp2
    q["pos"] = q["pos"] + q["vel"] * dt


def render(img, parts, p, origin_screen, px_per_world):
    """Composites the particles onto img (float RGB 0..255, HxWx3) in place, oldest first."""
    H, W = img.shape[:2]
    tw, th = p["texture"]
    col = np.array(p["color"][:3]) * 255.0
    base_a = p["color"][3]
    life = p["lifetime"]
    alpha_total = np.zeros((H, W))
    for q in sorted(parts, key=lambda q: -q["age"]):
        tt = min(q["age"] / life, 1.0)
        sc = q["scale"] * curve(p["scale_curve"], tt)
        a = base_a * float(np.interp(tt, p["ramp_offsets"], p["ramp_alpha"]))
        vy = q["vel"] / (np.linalg.norm(q["vel"]) + 1e-9)
        vx = np.array([-vy[1], vy[0]])
        cs = np.array(origin_screen) + q["pos"] * px_per_world
        half = max(tw, th) * sc * px_per_world * 0.5 + 2
        x0, x1 = int(max(0, cs[0] - half)), int(min(W, cs[0] + half + 1))
        y0, y1 = int(max(0, cs[1] - half)), int(min(H, cs[1] + half + 1))
        if x0 >= x1 or y0 >= y1:
            continue
        ys, xs = np.mgrid[y0:y1, x0:x1] + 0.5
        dx = (xs - cs[0]) / px_per_world; dy = (ys - cs[1]) / px_per_world
        lx = dx * vx[0] + dy * vx[1]; ly = dx * vy[0] + dy * vy[1]
        r = 2.0 * np.sqrt((lx / (tw * sc)) ** 2 + (ly / (th * sc)) ** 2)
        ta = np.interp(r, p["tex_offsets"], p["tex_alpha"], right=0.0)
        A = ta * a
        sub = img[y0:y1, x0:x1]
        sub[:] = col * A[..., None] + sub * (1 - A[..., None])
        alpha_total[y0:y1, x0:x1] = A + alpha_total[y0:y1, x0:x1] * (1 - A)
    return alpha_total


if __name__ == "__main__":
    print(json.dumps(P, indent=1))
