"""Collect the final measurements for the delivered rows into deliver/measurements.json.
Drift and slide come from measure2.py (guide-aware) and soles.py (guide-free) runs on the source
rows; px are given in final cell px and in 1080p game px (cell px x game scale).
Key spill: share of soft-edge pixels (alpha 8-247) whose colour leans magenta (min(R,B) - G > 20).
usage: report.py"""
import json, os, glob
import numpy as np
from PIL import Image
ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
ROWS = json.load(open(os.path.join(ROOT, 'tools', 'rows.json')))
LOOPS = json.load(open(os.path.join(ROOT, 'deliver', 'loops', 'loops.json')))
out = {}
for row, cfg in ROWS.items():
    src = os.path.basename(cfg['src'])
    m = json.load(open(os.path.join(ROOT, 'qa', src + '-measure.json')))
    so = os.path.join(ROOT, 'qa', src + '-soles.json')
    so = json.load(open(so)) if os.path.exists(so) else None
    gs = LOOPS[row]['game_scale']
    drift = {k: dict(max_cell=v['max_px'], mean_cell=v['mean_px'], seam_cell=v['seam_px'],
                     max_game1080=round(v['max_px'] * gs, 2)) for k, v in m['anchor_drift_cell_px'].items()}
    bf = m.get('foot_slide_at_best_fit_cell_px') or {}
    frames = sorted(glob.glob(os.path.join(ROOT, 'deliver', 'sprites', row, 'frame_*.png')))
    mag, edge, hs = 0, 0, []
    for f in frames:
        im = np.asarray(Image.open(f).convert('RGBA')).astype(int)
        a = im[..., 3]; e = (a >= 8) & (a <= 247)
        edge += int(e.sum()); mag += int((e & ((np.minimum(im[..., 0], im[..., 2]) - im[..., 1]) > 20)).sum())
        ys = np.nonzero((a >= 128).any(1))[0]; hs.append(int(ys.max() - ys.min() + 1))
    out[row] = dict(source=cfg['src'], frames=len(frames), game_scale_1080p=gs,
                    anchor_drift=drift,
                    foot_slide_guide_aware_cell=dict(max=bf.get('max'), p90=bf.get('p90'), mean=bf.get('mean'),
                                                     max_game1080=None if bf.get('max') is None else round(bf['max'] * gs, 2)),
                    foot_slide_guide_free_cell=None if so is None else dict(max=so['max'], p90=so['p90'], mean=so['mean'],
                                                                         max_game1080=round(so['max'] * gs, 2)),
                    contact_gap_max_px=m['contact_gap_px']['max_abs'], loop_seam=m['seam'],
                    opaque_height_px=dict(min=min(hs), max=max(hs)), height_cv=m['identity']['height_cv'],
                    edge_colour=m.get('edge'), magenta_spill_share_of_edge_px=round(mag / max(edge, 1), 4),
                    playback=LOOPS[row])
json.dump(out, open(os.path.join(ROOT, 'deliver', 'measurements.json'), 'w'), indent=1)
for r, v in out.items():
    d = v['anchor_drift']
    print(f"{r:10s} drift max(cell) " + ', '.join(f"{k} {x['max_cell']}" for k, x in d.items()),
          '| slide guide', v['foot_slide_guide_aware_cell']['max'], 'free', None if v['foot_slide_guide_free_cell'] is None else v['foot_slide_guide_free_cell']['max'],
          '| seam', v['loop_seam']['iou_last_first'], 'vs', v['loop_seam']['mean_consecutive_iou'], '| h', v['opaque_height_px'], 'cv', v['height_cv'],
          '| magenta edge', v['magenta_spill_share_of_edge_px'], '| edge da/db', v['edge_colour']['mean_da'], v['edge_colour']['mean_db'])
