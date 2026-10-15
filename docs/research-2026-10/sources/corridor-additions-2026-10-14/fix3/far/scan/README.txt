Round 10 pool-centring scan (not installed). far10.py run with WALL_EXTRA 9.0 (installed), 4.5, 2.0, 0.0, -3.0
and measured with a plate proxy of the real review's screen measure (plate scaled 0.9, rows 62-100 at 720p,
7 px smoothing): peak / centroid (screen x; fitting centre 687.5)
  9.0: 682 / 686.2 (proxy matches the render.sh capture's 682 / 684.9-685.0)
  4.5: 682 / 689.6
  2.0: 682 / 691.6
  0.0: 682 / 693.2
 -3.0: 694 / 695.6
The wall profile under the fitting is a flat plateau (within 3 levels from x ~670 to ~697 in the round-10
capture) and its argmax is a concrete texture feature at 682 (or 694 once moved further), so no shift puts
both peak and centroid nearer the fitting than 9.0 does; 9.0 stays installed (md5 a2db51a0cd09aa97c6f7a09b014cc98d).
