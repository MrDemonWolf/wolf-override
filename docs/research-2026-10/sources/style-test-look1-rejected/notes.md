# Variant 1 style test — generation, processing, and QA record

Date: 2026-10-10  
Mode: Codex built-in image generation only. No API key or billed image CLI was used.

## References

Every generation/edit call represented all seven approved references. The built-in tool permits up to five reference paths, so each call used keyart-b.png and both approved corridor plates directly, plus a temporary reference board containing the four approved engineer, WOLF, breaker, and coolant-relay sprites/props. The board is recorded here and was removed from temporary storage after use.

- art/keyart/keyart-b.png
- art/layers/corridor-far.png
- art/layers/corridor-mid.png
- art/sprites/rowan-side-right.png
- art/sprites/wolf-side-right.png
- art/props/corridor-breaker.png
- art/props/corridor-coolant-relay.png

## Prompt ledger

The prompt blocks below capture the generation instructions and change-only edit directions used. The shared style add-on is quoted verbatim from the art bible.

**Shared style add-on:** “match the painterly brushwork of image 2, reduce fine texture and grain by half, keep large shapes”. Applied to the plate and cut-outs. Also specified clean opaque silhouettes, top/rim light, cool neutrals, no dark outlines, no fine detail below the 960 px screen-size rule, and no text.

**Plate — base prompt:** Create the Variant 1 “current look, cleaned” opaque corridor plate at 1672x941. Use key art B for mood and palette and the approved far/mid corridor plates for the corridor structure. Keep the large painterly forms and cool navy/cyan lighting. Do not include actors, stations, labels, signs, or text. Put the wall/deck walkline at raw row 697, strip lamps near x=36% and x=75%, a dark gap behind WOLF, and wet deck reflections below the walkline.

**Plate — edit direction:** Keep the corridor composition and lighting; move the wall/deck walkline to raw row 697 while preserving the lamps, dark center gap, wet floor, and empty plate.

**Engineer — base prompt:** Create one full-body transparent cut-out matching the approved side-view engineer. Keep the deep-red hooded field jacket with hood down, black harness and utility belt, small cyan equipment light, charcoal trousers, gloves, dark boots, and short tousled brown hair. Keep two arms and two legs, a readable side-view pose, and a 280 px body height at D=4. No text.

**WOLF — base prompt:** Create one transparent side-view cut-out of the fully robotic wolf. Keep grey-blue angular armour, circular mechanical leg joints, cyan eye and restrained cyan seams, and an articulated segmented armour tail. Exactly two triangular ears, four legs, and four paws; no fur or extra limbs. Keep WOLF smaller in height than the engineer and 460 px long at D=4. No text.

**WOLF — edit direction:** Turn the head/gaze back toward the engineer on the left while preserving the approved robotic body, four-leg silhouette, ears, and segmented tail.

**Breaker — base prompt:** Create one transparent cut-out of the approved corridor breaker, preserving its recognizable industrial switch, housing, and conduit. Target a 388 px body height at D=4. Use cool steel grading, painterly broad forms, top/rim light, and no text.

**Coolant relay — base prompt:** Create one transparent cut-out of the approved coolant relay, preserving its recognizable housing, circular relay core, and side coolant pipe. Target a 356 px body height at D=4. Keep the materials cool, with cyan lighting restrained to the approved equipment accents. No text.

**Coolant relay — edit direction:** Regrade the warm/gold connector pins to cool neutral metal; preserve the relay silhouette and cyan core.

**Cut-out cleanup directions:** Keep each approved design and silhouette; reduce fine grain and microtexture; retain large painterly shapes; remove dark outlines and matte fringe; keep bodies opaque; restore cool grading and readable top/rim light. WOLF used a lighter 0.5 px detail-softening pass after the heavier 1.25 px pass looked over-smoothed.

## Processing and placement

- Plate: resized from 1672x941 to 1920x1080 at 1.148x with a high-quality Lanczos filter.
- Cut-outs: RGBA on transparent backgrounds, padded to multiple-of-16 canvases. Matte/edge cleanup removed dark and cyan spill; the final D=4 opaque body bounds are engineer 280 px tall, WOLF 460x246 px, breaker 388 px tall, and relay 356 px tall.
- Composite: assets placed at 2/3 scale on the plate with a shared floor baseline. Exported at 1920x1080, 1280x720, and 960x540. crop-960-2x.png is a center crop from the 960 composite enlarged 2x.
- The final one-pixel contour adjustments were followed by a complete QA rerun.

## QA results

All five requested qa_asset.py runs used python3 -I and wrote JSON manifests under qa/. Checks A-G pass for every cut-out; composite QA passes. Engineer and WOLF also passed the local 960-composite H contrast/lost-detail precheck.

| Asset | A alpha body | B holes | C dark/halo/chroma | D baseline | G noise / high-frequency | H lost / contrast |
|---|---:|---:|---|---:|---|---|
| engineer | 0.9993 | 0.0007 | 0 / 0 / 0.06 | 310 (target 311 ±1) | 4.37 / 0.148 | 0.037 / 2.03 |
| WOLF | 0.9998 | 0.0002 | 0 / 0 / 0.01 | 263 | 5.49 / 0.163 | 0.017 / 2.89 |
| breaker | 0.9999 | 0.0001 | 0.0014 / 0 / 0.03 | 407 | 4.53 / 0.133 | n/a |
| coolant relay | 0.9998 | 0.0002 | 0.0026 / 0.0009 / 2.30 | 375 | 1.50 / 0.153 | n/a |
| composite-960 | pass | — | cool neutrals/accent check passes | — | — | — |

JSON files: qa/engineer.json, qa/wolf.json, qa/breaker.json, qa/relay.json, qa/composite.json.

Manual visual checks: WOLF has two ears and four paws; the engineer matches the specified costume; the plate contains no actors or stations; the assets and composite contain no text.

## Failed attempts and corrections

- The first seven-path reference request was rejected by the built-in tool’s five-path limit before generation. No image was created by that rejected call. The reference-board workaround included all seven approved designs in every subsequent call.
- The first plate put the wall/deck walkline too high; the plate was regenerated/edited to the required raw row 697.
- The first WOLF result did not look back toward the engineer; a head/gaze edit corrected it.
- The first coolant relay had warm gold pins; an edit cooled the pins.
- Initial cut-out QA found matte fringe, outline, grain, color, and high-frequency issues. Cleanup/regrading and final edge processing brought all A-G checks into range. The relay’s first high-frequency share was 0.312; the final value is 0.153. WOLF’s heavier blur met noise limits but lost too much surface detail, so it was replaced with the sharper 0.5 px pass, which passes G at noise 5.49 and high-frequency share 0.163.
- The final body-bound adjustment matched each specified D=4 height/length, then all QA was rerun. No remaining QA failures.

## Metadata and workspace

Yes, metadata was removed from the delivered PNGs. The final files were re-encoded during processing; their PNG metadata dictionaries are empty and no C2PA/cabx/jumb payload remains. The built-in generated originals remain in the Codex generated-images directory. Approved source references were not modified.

No V2 output or comparison review sheet was created: this delivery is Variant 1 only, and the requested file list does not include a cross-variant sheet.

No Git repository was written.
