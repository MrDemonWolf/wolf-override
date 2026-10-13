
### A. Shipping default: 60 FPS cap + V-Sync, 1280x720 window

Median of runs def-2, def-3, def-4.

| State | FPS | frame avg ms | p50 | p99 | worst | script _process ms/frame | physics ms/frame | render CPU ms/frame | process CPU % of a core | GPU busy % | draw calls | objects drawn | primitives |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Title | 66 | 15.05 | 14.09 | 25.98 | 32.5 | 0.11 | 0.047 | 0.60 | 16 | 44 | 88 | 334 | 4150 |
| Corridor start, idle | 44 | 22.94 | 23.58 | 26.29 | 29.1 | 0.27 | 0.082 | 0.56 | 13 | 41 | 68 | 422 | 3514 |
| Corridor start, walking | 45 | 22.03 | 23.03 | 29.01 | 93.4 | 0.24 | 0.078 | 0.54 | 13 | 40 | 63 | 219 | 2256 |
| Corridor relay, idle | 44 | 22.76 | 21.95 | 26.50 | 69.8 | 0.23 | 0.072 | 0.60 | 13 | 38 | 78 | 282 | 3128 |
| Corridor relay, walking | 45 | 22.38 | 23.35 | 26.04 | 31.7 | 0.23 | 0.076 | 0.57 | 12 | 40 | 74 | 248 | 2634 |
| Records, idle | 44 | 22.97 | 23.72 | 26.50 | 28.2 | 0.21 | 0.073 | 0.48 | 12 | 40 | 55 | 249 | 2288 |
| Records, walking | 46 | 21.64 | 22.18 | 25.84 | 55.1 | 0.20 | 0.071 | 0.49 | 12 | 41 | 55 | 182 | 1728 |
| Junction entry (WOLF scouts) | 44 | 22.82 | 22.61 | 26.51 | 43.1 | 0.26 | 0.082 | 0.75 | 14 | 37 | 98 | 294 | 4038 |
| Junction blast, played (arm, crank, fuse, door, 3 s after) | 42 | 23.73 | 24.36 | 30.12 | 44.3 | 0.32 | 0.069 | 0.78 | 15 | 40 | 102 | 349 | 4578 |
| Junction after blast, idle | 43 | 23.10 | 23.84 | 27.10 | 33.4 | 0.30 | 0.071 | 0.76 | 14 | 40 | 100 | 390 | 4192 |
| Junction after blast, walking | 43 | 23.22 | 23.94 | 26.52 | 52.7 | 0.31 | 0.074 | 0.80 | 15 | 36 | 106 | 398 | 4208 |
| Sentry lane (WOLF baits, sentry fixates) | 43 | 23.05 | 23.65 | 26.23 | 41.1 | 0.27 | 0.069 | 0.81 | 14 | 40 | 109 | 387 | 4186 |

Worst state by average frame: 23.73 ms; worst p99: 30.12 ms; CPU 12 to 16% of a core.

### B. V-Sync only (cap off), 1280x720 window, 120 Hz display

Median of runs vsync-1.

| State | FPS | frame avg ms | p50 | p99 | worst | script _process ms/frame | physics ms/frame | render CPU ms/frame | process CPU % of a core | GPU busy % | draw calls | objects drawn | primitives |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Title | 120 | 8.35 | 8.36 | 12.20 | 17.1 | 0.12 | 0.029 | 0.57 | 24 | 52 | 88 | 334 | 4150 |
| Corridor start, idle | 120 | 8.36 | 8.29 | 12.37 | 17.5 | 0.28 | 0.035 | 0.50 | 25 | 49 | 68 | 415 | 3500 |
| Corridor start, walking | 120 | 8.34 | 8.10 | 11.90 | 18.5 | 0.25 | 0.037 | 0.50 | 26 | 48 | 63 | 219 | 2256 |
| Corridor relay, idle | 120 | 8.33 | 8.32 | 12.42 | 14.6 | 0.23 | 0.031 | 0.53 | 25 | 49 | 78 | 282 | 3128 |
| Corridor relay, walking | 119 | 8.40 | 8.33 | 12.47 | 17.8 | 0.23 | 0.033 | 0.52 | 25 | 48 | 74 | 248 | 2634 |
| Records, idle | 120 | 8.34 | 8.35 | 12.10 | 16.5 | 0.21 | 0.031 | 0.44 | 23 | 50 | 55 | 249 | 2288 |
| Records, walking | 120 | 8.35 | 8.26 | 11.91 | 17.5 | 0.22 | 0.032 | 0.45 | 24 | 48 | 55 | 182 | 1728 |
| Junction entry (WOLF scouts) | 120 | 8.35 | 8.24 | 12.42 | 17.0 | 0.27 | 0.035 | 0.69 | 30 | 49 | 98 | 294 | 4038 |
| Junction blast, played (arm, crank, fuse, door, 3 s after) | 118 | 8.50 | 8.20 | 13.25 | 65.0 | 0.35 | 0.040 | 0.75 | 32 | 50 | 102 | 343 | 4576 |
| Junction after blast, idle | 119 | 8.40 | 8.13 | 12.30 | 28.0 | 0.32 | 0.032 | 0.71 | 31 | 48 | 100 | 394 | 4200 |
| Junction after blast, walking | 116 | 8.65 | 8.05 | 20.28 | 46.9 | 0.33 | 0.034 | 0.74 | 31 | 54 | 104 | 398 | 4208 |
| Sentry lane (WOLF baits, sentry fixates) | 120 | 8.37 | 8.10 | 12.12 | 18.3 | 0.28 | 0.030 | 0.73 | 30 | 51 | 109 | 387 | 4186 |

Worst state by average frame: 8.65 ms; worst p99: 20.28 ms; CPU 23 to 32% of a core.

### C. Uncapped (cap off, V-Sync off), 1280x720 window: raw frame cost

Median of runs unc-2, unc-3, unc-4.

| State | FPS | frame avg ms | p50 | p99 | worst | script _process ms/frame | physics ms/frame | render CPU ms/frame | process CPU % of a core | GPU busy % | draw calls | objects drawn | primitives |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Title | 236 | 4.23 | 4.68 | 7.65 | 28.6 | 0.11 | 0.014 | 0.55 | 38 | 66 | 88 | 334 | 4150 |
| Corridor start, idle | 240 | 4.17 | 3.92 | 7.68 | 13.2 | 0.24 | 0.016 | 0.47 | 40 | 59 | 68 | 415 | 3500 |
| Corridor start, walking | 239 | 4.19 | 3.94 | 7.89 | 12.6 | 0.21 | 0.016 | 0.46 | 40 | 58 | 63 | 219 | 2256 |
| Corridor relay, idle | 235 | 4.25 | 4.64 | 8.07 | 14.7 | 0.20 | 0.015 | 0.51 | 41 | 59 | 78 | 282 | 3128 |
| Corridor relay, walking | 243 | 4.12 | 2.79 | 7.70 | 22.1 | 0.19 | 0.015 | 0.48 | 40 | 59 | 74 | 248 | 2634 |
| Records, idle | 250 | 4.01 | 2.47 | 7.40 | 22.7 | 0.18 | 0.014 | 0.41 | 38 | 59 | 55 | 249 | 2288 |
| Records, walking | 253 | 3.96 | 2.49 | 7.35 | 13.5 | 0.18 | 0.013 | 0.41 | 38 | 59 | 55 | 182 | 1728 |
| Junction entry (WOLF scouts) | 230 | 4.35 | 4.85 | 8.08 | 18.1 | 0.24 | 0.018 | 0.66 | 48 | 58 | 98 | 294 | 4038 |
| Junction blast, played (arm, crank, fuse, door, 3 s after) | 216 | 4.62 | 4.95 | 8.99 | 29.3 | 0.30 | 0.017 | 0.68 | 48 | 58 | 101 | 343 | 4576 |
| Junction after blast, idle | 224 | 4.46 | 4.89 | 8.67 | 16.5 | 0.29 | 0.015 | 0.67 | 48 | 58 | 100 | 394 | 4200 |
| Junction after blast, walking | 212 | 4.72 | 5.19 | 9.16 | 14.6 | 0.30 | 0.018 | 0.70 | 48 | 58 | 107 | 397 | 4208 |
| Sentry lane (WOLF baits, sentry fixates) | 225 | 4.45 | 4.86 | 8.45 | 22.2 | 0.26 | 0.016 | 0.72 | 49 | 58 | 109 | 387 | 4186 |

Worst state by average frame: 4.72 ms; worst p99: 9.16 ms; CPU 38 to 49% of a core.

### D. Uncapped, 960x540 window (the size the earlier figures used)

Median of runs unc-960.

| State | FPS | frame avg ms | p50 | p99 | worst | script _process ms/frame | physics ms/frame | render CPU ms/frame | process CPU % of a core | GPU busy % | draw calls | objects drawn | primitives |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Title | 250 | 4.00 | 2.35 | 7.83 | 29.2 | 0.11 | 0.013 | 0.54 | 39 | 57 | 88 | 334 | 4150 |
| Corridor start, idle | 242 | 4.14 | 2.74 | 7.83 | 13.2 | 0.25 | 0.016 | 0.49 | 43 | 53 | 68 | 415 | 3500 |
| Corridor start, walking | 242 | 4.12 | 2.67 | 8.46 | 14.3 | 0.22 | 0.016 | 0.47 | 42 | 52 | 63 | 219 | 2256 |
| Corridor relay, idle | 252 | 3.97 | 2.40 | 7.72 | 9.5 | 0.20 | 0.013 | 0.50 | 42 | 54 | 78 | 282 | 3128 |
| Corridor relay, walking | 256 | 3.90 | 2.27 | 7.65 | 11.2 | 0.19 | 0.014 | 0.48 | 41 | 54 | 74 | 248 | 2634 |
| Records, idle | 244 | 4.09 | 2.30 | 7.82 | 10.8 | 0.18 | 0.014 | 0.42 | 39 | 53 | 55 | 249 | 2288 |
| Records, walking | 261 | 3.83 | 2.09 | 7.36 | 10.6 | 0.18 | 0.013 | 0.41 | 40 | 53 | 55 | 182 | 1728 |
| Junction entry (WOLF scouts) | 223 | 4.48 | 5.13 | 8.48 | 13.0 | 0.25 | 0.018 | 0.69 | 48 | 51 | 98 | 294 | 4038 |
| Junction blast, played (arm, crank, fuse, door, 3 s after) | 230 | 4.34 | 4.93 | 8.25 | 18.0 | 0.26 | 0.013 | 0.68 | 48 | 52 | 102 | 343 | 4576 |
| Junction after blast, idle | 238 | 4.21 | 4.67 | 7.61 | 9.4 | 0.24 | 0.012 | 0.67 | 48 | 52 | 100 | 394 | 4200 |
| Junction after blast, walking | 226 | 4.42 | 5.05 | 8.47 | 18.0 | 0.28 | 0.014 | 0.69 | 48 | 52 | 104 | 395 | 4202 |
| Sentry lane (WOLF baits, sentry fixates) | 202 | 4.94 | 5.38 | 9.60 | 17.2 | 0.26 | 0.016 | 0.77 | 48 | 50 | 109 | 387 | 4186 |

Worst state by average frame: 4.94 ms; worst p99: 9.60 ms; CPU 39 to 48% of a core.

### E. Shipping default at 1920x1080 window

Median of runs def-1080.

| State | FPS | frame avg ms | p50 | p99 | worst | script _process ms/frame | physics ms/frame | render CPU ms/frame | process CPU % of a core | GPU busy % | draw calls | objects drawn | primitives |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Title | 67 | 14.86 | 11.67 | 25.43 | 29.1 | 0.12 | 0.046 | 0.63 | 16 | 50 | 88 | 334 | 4150 |
| Corridor start, idle | 44 | 22.96 | 22.65 | 25.93 | 27.2 | 0.29 | 0.083 | 0.57 | 12 | 46 | 68 | 422 | 3514 |
| Corridor start, walking | 43 | 23.19 | 23.23 | 25.70 | 26.1 | 0.23 | 0.080 | 0.54 | 12 | 43 | 63 | 218 | 2254 |
| Corridor relay, idle | 44 | 22.98 | 22.91 | 25.82 | 26.2 | 0.22 | 0.069 | 0.58 | 12 | 43 | 78 | 282 | 3128 |
| Corridor relay, walking | 43 | 23.04 | 22.78 | 28.39 | 30.4 | 0.23 | 0.078 | 0.58 | 12 | 44 | 74 | 248 | 2634 |
| Records, idle | 44 | 22.63 | 22.07 | 25.63 | 32.7 | 0.21 | 0.072 | 0.51 | 12 | 39 | 55 | 249 | 2288 |
| Records, walking | 44 | 22.77 | 22.53 | 25.47 | 25.5 | 0.21 | 0.074 | 0.50 | 12 | 43 | 55 | 182 | 1728 |
| Junction entry (WOLF scouts) | 43 | 23.08 | 22.77 | 26.23 | 26.9 | 0.27 | 0.082 | 0.76 | 15 | 42 | 98 | 294 | 4038 |
| Junction blast, played (arm, crank, fuse, door, 3 s after) | 43 | 23.37 | 23.18 | 29.68 | 51.4 | 0.33 | 0.072 | 0.82 | 16 | 38 | 102 | 349 | 4578 |
| Junction after blast, idle | 44 | 22.84 | 22.66 | 26.10 | 27.8 | 0.31 | 0.073 | 0.78 | 15 | 41 | 100 | 390 | 4192 |
| Junction after blast, walking | 43 | 23.30 | 22.90 | 26.50 | 51.9 | 0.32 | 0.076 | 0.80 | 15 | 43 | 104 | 397 | 4206 |
| Sentry lane (WOLF baits, sentry fixates) | 44 | 22.96 | 22.57 | 26.48 | 41.2 | 0.28 | 0.070 | 0.82 | 15 | 40 | 109 | 387 | 4186 |

Worst state by average frame: 23.37 ms; worst p99: 29.68 ms; CPU 12 to 16% of a core.
