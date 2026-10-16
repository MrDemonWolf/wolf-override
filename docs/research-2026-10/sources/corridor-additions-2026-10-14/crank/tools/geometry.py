"""Shared geometry for the crank pose: the game's numbers, turned into engineer-cell pixels.

Game (real-slice/game-slice/apps/game, main 76d3a50 + round 6):
  main.gd       BYPASS_WHEEL = (700, 398), BYPASS_CRANK_X = BYPASS_WHEEL.x - 26 = 674
  bypass_handle WHEEL_OFFSET = (-6, 2)  -> hub at world (694, 400)
                WHEEL_REGION 88x88 atlas px at WHEEL_SCALE 0.25 (rim tube centre radius 37.5 atlas px,
                measured from the alpha/luma profile: tube 34-41 atlas px) -> 9.375 world px
                ticks: 8 per turn, 45 deg clockwise each, tween 0.18 s; HoldUse.TICK_SECONDS 0.4
  Main.tscn     Human at y 410 on the floor (floor top 440); the engineer is 70 world px tall
Approved frames (docs/research-2026-10/sources/walk-final-2026-10-11/engineer):
  cell 256x320, feet baseline row 311 (lowest opaque row; its bottom edge is y 312), pivot x 128,
  figure 277 px tall; world scale 0.254 per cell px (walk 15.3 fps at 80 px/s and 20.58 cell px per
  frame -> 3.937 cell px per world px; 277 x 0.254 = 70.4 world px, the provisional sprite's 70.3).
"""
import math

CELL_W, CELL_H = 256, 320
BASE_ROW = 311          # lowest opaque row of the feet
PIVOT_X = 128
WORLD_PER_CELL = 0.254  # world px per cell px
CELL_PER_WORLD = 1.0 / WORLD_PER_CELL

# world
FLOOR_Y = 440.0
HUMAN_Y = 410.0
CRANK_X = 674.0
HUB_W = (694.0, 400.0)
RIM_R_W = 9.375
# the sprite's offset from the Human node so the baseline row's bottom edge (312) sits on the floor
SPRITE_OFFSET_Y = round(FLOOR_Y - HUMAN_Y - (BASE_ROW + 1 - CELL_H / 2) * WORLD_PER_CELL, 2)  # -8.61


def world_to_cell(x, y):
    """World point -> cell px, with the engineer standing at CRANK_X, facing right."""
    cx = PIVOT_X + (x - CRANK_X) * CELL_PER_WORLD
    cy = CELL_H / 2 + (y - (HUMAN_Y + SPRITE_OFFSET_Y)) * CELL_PER_WORLD
    return cx, cy


HUB = world_to_cell(*HUB_W)
RIM_R = RIM_R_W * CELL_PER_WORLD


def rim_point(clock_deg):
    """Point on the rim's tube centre at a clock angle (0 = 12 o'clock, clockwise, 240 = 8 o'clock)."""
    a = math.radians(clock_deg)
    return HUB[0] + RIM_R * math.sin(a), HUB[1] - RIM_R * math.cos(a)


# The grip: frame A holds the rim at 8 o'clock (240 deg); one tick turns the wheel 45 deg clockwise,
# so in frame B the same rim point (and the glove on it) has moved to 285 deg (about half past 9).
GRIP_A_DEG = 240.0
GRIP_B_DEG = GRIP_A_DEG + 45.0
GRIP_A = rim_point(GRIP_A_DEG)
GRIP_B = rim_point(GRIP_B_DEG)

if __name__ == '__main__':
    print('sprite offset y', SPRITE_OFFSET_Y)
    print('hub cell', HUB, 'rim r cell', RIM_R)
    print('grip A', GRIP_A, 'grip B', GRIP_B)
