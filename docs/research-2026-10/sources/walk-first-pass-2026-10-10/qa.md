# WOLF//OVERRIDE sprite animation QA

This is game sprite output only. No pet package, look-direction rows, or repository changes were created.

## Pipeline and common checks

- Chroma extraction used hatch-pet `extract_strip_frames.py` with the explicit `stable-slots` method and #00FF00 key; `inspect_frames.py --allow-stable-slots` checked extracted cells; `despill_chroma_edges.py` cleaned keyed edges.
- Left-facing frames were produced by `mirror_strip_preserving_frame_order`, preserving frame order. Preview files use hatch-pet `render_animation_previews.py` `save_preview`.
- Final PNGs were re-encoded from the generated images. Source metadata keys are listed per row; Pillow output files were saved without copying metadata.
- Fixed canvas sizes: engineer 256×384; WOLF 384×208. Sprite normalization uses one scale per row, a cyan-light/seam anchor where detected, a fixed hip/torso target, and one shared baseline per row. Baseline snapping applies only to support frames; flight frames remain above it.

## Row measurements and worker QA

### engineer/idle

- Source: `[Codex generated-images store]/01a12760-9a15-78e2-9e4c-2e2655dcade1/exec-cd0552b2-d4ad-4719-a92e-cb9792ba3f8e.png`; SHA-256 `8a5864826ac7507832d574b8c278b06da89d5b8fab6804ecdd76c0a22708312b`; source size 1212×1297; grid 3x2; Pillow info keys: none; metadata audit: inspect_file.py found C2PA/AI metadata in a caBX PNG chunk; ExifTool identified C2PA JUMBF labels..
- Frames: 6; final canvas 256×384; extraction report: `{'ok': True, 'frames_root': '[session scratch, not kept]/art/anim/.work/extracted/engineer/idle', 'states': ['idle']}`; inspect report: `{'ok': True, 'frames_root': '[session scratch, not kept]/art/anim/.work/extracted/engineer/idle', 'states': ['idle'], 'errors': [], 'warnings': ['idle used extraction method stable-slots; component extraction is preferred']}`.
- Anchor: cyan-light-centroid; fixed target mean [129.33, 297.42] px; maximum frame-to-frame drift 8.09 px.
- Visible character bounds (width min/median/max × height min/median/max): [76, 77.0, 77] × [190, 190.0, 190] px; target height/length 190 px.
- Foot baseline: y=366; max support-frame deviation 0 px after snapping; per-frame snap adjustments {'0': 2, '1': 3, '2': -4, '3': -2, '4': -3, '5': 4}; non-support/flight foot bottoms {}.
- Loop seam (last→first): silhouette IoU 0.9396; RGBA mean absolute pixel difference 1.978; first/last alpha bounds [96, 176, 173, 366] / [97, 176, 174, 366].
- Contact indices by foot: `{"left_boot": [0, 1, 2, 3, 4, 5], "right_boot": [0, 1, 2, 3, 4, 5]}`.
- Contact QA: All six idle frames are grounded; these indices describe stance, not sound triggers.
- Worker QA: Pass for identity, outfit colors, six right-facing frames, flat key, scale and planted baseline. Worker observed subtle chest, shoulder and jacket-fold changes; breathing remains intentionally small.
- Outputs: right `engineer/idle/frame_00.png` … `engineer/idle/frame_05.png`; mirrored `engineer/idle-left/frame_00.png` … `engineer/idle-left/frame_05.png`; sheet `engineer/idle-sheet.png`.

#### Prompt used for selected source

```text
Painterly 2D side-view sci-fi horror game sprite row for WOLF//OVERRIDE. Generate exactly 6 sequential full-body frames of the engineer, facing screen-right and standing in place. Image 1 is the canonical identity reference; match its face, hair, hood, deep-red field jacket, charcoal trousers, dark boots, cyan equipment light, proportions, and painterly material detail exactly. Never add yellow patches or shiny silver knee armor. Image 2 is lighting/rendering style only: cool blue-black cinematic edge light and textured painterly shading; do not include a corridor or environment. Image 3 is a layout-only 3-column by 2-row guide; read left-to-right, then continue on the next row. Ignore its guide lines and colors.

Each equal cell is portrait 2:3, one full-body pose, same character scale, with the hip pivot fixed at the same point in every cell. Keep both boots resting on one shared baseline in every frame. Sequence: 00 neutral; 01 subtle inhale; 02 slight chest rise; 03 tiny weight shift while both boots stay planted; 04 gentle exhale; 05 settle back to 00. Breathing and weight shift only; no walking, no lifted feet. Make frame 05 meet frame 00 smoothly.

Use a perfectly flat, uniform #00FF00 chroma-key background in every cell. No scenery, floor, ground plane, shadows, motion lines, text, labels, cell borders, guide marks, duplicated panels, detached effects, or glow outside the body. Keep the character fully inside each cell with clear gaps between poses.

Final retry: This idle row must show a readable breathing animation in a contact sheet. Use a subtle but clear 4% body-height chest rise and shoulder lift on inhale, then return on exhale; jacket folds and hood move with the chest. Frame 00 is neutral, 01 begins the inhale, 02 is the raised-chest peak, 03 is a slight hip weight shift while both boots remain planted, 04 is the lowered-chest exhale, and 05 settles back to frame 00. Make frames 01 through 04 visibly distinct from their neighbors; do not duplicate a standing pose. Keep the head and face unchanged, the character facing right, and both boots aligned to one baseline.
```

### engineer/walk

- Source: `[Codex generated-images store]/01a12762-2df1-7483-96c8-45a3fdd5e3e9/exec-17f312e4-1e51-4e74-a3f3-3a66e5acd726.png`; SHA-256 `fa0939eb92093cdacb9c5ce56c3dc4bd315f1452a28dcbe1dae4325dc81e3131`; source size 1448×1086; grid 4x2; Pillow info keys: none; metadata audit: inspect_file.py found C2PA/AI metadata in a caBX PNG chunk; ExifTool identified C2PA JUMBF labels..
- Frames: 8; final canvas 256×384; extraction report: `{'ok': True, 'frames_root': '[session scratch, not kept]/art/anim/.work/extracted/engineer/walk', 'states': ['running-right']}`; inspect report: `{'ok': True, 'frames_root': '[session scratch, not kept]/art/anim/.work/extracted/engineer/walk', 'states': ['running-right'], 'errors': [], 'warnings': ['running-right used extraction method stable-slots; component extraction is preferred']}`.
- Anchor: cyan-light-centroid; fixed target mean [126.62, 302.5] px; maximum frame-to-frame drift 13.92 px.
- Visible character bounds (width min/median/max × height min/median/max): [80, 112.0, 132] × [187, 190.0, 191] px; target height/length 190 px.
- Foot baseline: y=366; max support-frame deviation 0 px after snapping; per-frame snap adjustments {'0': -4, '1': 10, '2': 4, '3': -4, '4': -6, '5': 11, '6': 4, '7': -13}; non-support/flight foot bottoms {}.
- Loop seam (last→first): silhouette IoU 0.7915; RGBA mean absolute pixel difference 4.645; first/last alpha bounds [71, 176, 195, 366] / [73, 175, 199, 366].
- Contact indices by foot: `{"left_boot": [0], "right_boot": [4]}`.
- Contact QA: Worker verified left boot touchdown at frame 00 and right boot touchdown at frame 04.
- Worker QA: Pass for eight right-facing frames, consistent engineer identity/outfit, flat key, visible opposite arm/leg swing and distinct left/right contact poses. Worker noted small baseline variation before deterministic alignment.
- Outputs: right `engineer/walk/frame_00.png` … `engineer/walk/frame_07.png`; mirrored `engineer/walk-left/frame_00.png` … `engineer/walk-left/frame_07.png`; sheet `engineer/walk-sheet.png`.

#### Prompt used for selected source

```text
Painterly 2D side-view sci-fi horror game sprite row for WOLF//OVERRIDE. Generate exactly 8 sequential full-body frames of the engineer in a calm cautious walk cycle, facing and travelling screen-right in place. Image 1 is the canonical identity reference; match its face, hair, hood, deep-red field jacket, charcoal trousers, dark boots, cyan equipment light, proportions, and painterly material detail exactly. Never add yellow patches or shiny silver knee armor. Image 2 is lighting/rendering style only: cool blue-black cinematic edge light and textured painterly shading; do not include a corridor or environment. Image 3 is a layout-only 4-column by 2-row guide; read left-to-right, then continue on the next row. Ignore its guide lines and colors.

Each equal cell is portrait 2:3, one full-body pose, same character scale, with the hip pivot fixed at the same point in every cell. Keep all boots at or above one shared baseline; contact frames touch it exactly. Sequence: 00 left-foot contact; 01 down/compression; 02 passing; 03 up; 04 right-foot contact; 05 down/compression; 06 passing; 07 up, returning smoothly to 00. Use a complete alternating stride with arms swinging opposite the legs. No running or flight phase. Left and right mean the engineer's anatomical legs.

Use a perfectly flat, uniform #00FF00 chroma-key background in every cell. No scenery, floor, ground plane, shadows, motion lines, text, labels, cell borders, guide marks, duplicated panels, detached effects, or glow outside the body. Keep the character fully inside each cell with clear gaps between poses.

Final walk retry: Increase the arm counter-swing until it is obvious in the contact poses. At frame 00 the left boot is forward and the right arm is forward; at frame 04 the right boot is forward and the left arm is forward. The hands should trade clearly between forward and back positions, roughly one glove-width of visible change relative to the torso. Keep all eight figures facing screen-right in profile. Show distinct down, passing, and up poses between those contacts; do not repeat adjacent poses or add a flight phase.
```

### engineer/jog

- Source: `[Codex generated-images store]/01a12760-7d37-7493-9ce0-263bf8e3ff27/exec-3cb123e7-b4f8-493e-a53f-cc036a4b2b08.png`; SHA-256 `0f63df31e9fc8be2c33a48f7ee6e3ffa6b15358c163ec3e198be237d9450ee6d`; source size 1448×1086; grid 4x2; Pillow info keys: none; metadata audit: inspect_file.py found C2PA/AI metadata in a caBX PNG chunk; ExifTool identified C2PA JUMBF labels..
- Frames: 8; final canvas 256×384; extraction report: `{'ok': True, 'frames_root': '[session scratch, not kept]/art/anim/.work/extracted/engineer/jog', 'states': ['running-right']}`; inspect report: `{'ok': True, 'frames_root': '[session scratch, not kept]/art/anim/.work/extracted/engineer/jog', 'states': ['running-right'], 'errors': [], 'warnings': ['running-right used extraction method stable-slots; component extraction is preferred']}`.
- Anchor: cyan-light-centroid; fixed target mean [128.12, 302.94] px; maximum frame-to-frame drift 7.18 px.
- Visible character bounds (width min/median/max × height min/median/max): [103, 123.0, 139] × [180, 190.0, 193] px; target height/length 190 px.
- Foot baseline: y=366; max support-frame deviation 0 px after snapping; per-frame snap adjustments {'0': 0, '1': 7, '2': 2, '4': -4, '5': 0, '6': -4}; non-support/flight foot bottoms {'3': 360, '7': 359}.
- Loop seam (last→first): silhouette IoU 0.5165; RGBA mean absolute pixel difference 8.78; first/last alpha bounds [79, 173, 206, 366] / [68, 179, 191, 359].
- Contact indices by foot: `{"flight": [3, 7], "left_boot": [0], "right_boot": [4]}`.
- Contact QA: Worker verified left boot touchdown at frame 00, right boot touchdown at frame 04, and flight at frames 03/07.
- Worker QA: Pass for eight right-facing frames, correct canonical outfit and proportions, counter-swing, contacts at 00/04, compression at 01/05, passing at 02/06 and clear flight at 03/07. Worker confirmed no yellow patches or shiny silver knees.
- Outputs: right `engineer/jog/frame_00.png` … `engineer/jog/frame_07.png`; mirrored `engineer/jog-left/frame_00.png` … `engineer/jog-left/frame_07.png`; sheet `engineer/jog-sheet.png`.

#### Prompt used for selected source

```text
Painterly 2D side-view sci-fi horror game sprite row for WOLF//OVERRIDE. Generate exactly 8 sequential full-body frames of a purposeful controlled jog, facing and travelling screen-right in place; this is not a sprint. Image 1 is the canonical identity reference; match its face, hair, hood, deep-red field jacket, charcoal trousers, dark boots, cyan equipment light, proportions, and painterly material detail exactly. Never add yellow patches or shiny silver knee armor. Image 2 is lighting/rendering style only: cool blue-black cinematic edge light and textured painterly shading; do not include a corridor or environment. Image 3 is a layout-only 4-column by 2-row guide; read left-to-right, then continue on the next row. Ignore its guide lines and colors.

Each equal cell is portrait 2:3, one full-body pose, same character scale, with the hip pivot fixed at the same point in every cell. Keep ground-contact boots on one shared baseline exactly. Sequence: 00 left-foot contact; 01 down/compression; 02 passing; 03 clear flight with both boots off the baseline; 04 right-foot contact; 05 down/compression; 06 passing; 07 clear flight with both boots off the baseline, returning smoothly to 00. Arms swing opposite the legs. At 12 fps, use a stride amplitude that reads as about 2.6 body heights per second. Keep the posture cautious and purposeful, with no sprint crouch.

Use a perfectly flat, uniform #00FF00 chroma-key background in every cell. No scenery, floor, ground plane, shadows, motion lines, dust, text, labels, cell borders, guide marks, duplicated panels, detached effects, or glow outside the body. Keep the character fully inside each cell with clear gaps between poses.

Retry constraints: Every one of the eight cells faces screen-right in the same side profile; do not show any screen-left-facing figure. Keep the sequence one continuous jog cycle: 00 left-foot contact, 01 compression, 02 passing, 03 clear flight with both boots visibly above baseline, 04 right-foot contact, 05 compression, 06 passing, 07 clear flight with both boots visibly above baseline. Frames 03 and 07 must show a definite flight gap; all other frames keep at least one boot on the shared baseline. The engineer remains the same scale and identity in every cell, with no repeated adjacent poses.
```

### wolf/idle

- Source: `[Codex generated-images store]/01a1275d-613b-76f1-8b80-57f06b999a07/exec-e47b2e3d-cd79-48ba-ab01-5923f212b4ee.png`; SHA-256 `dc8d99d54b899b47f9c0f1bce4b66bb23a4f22bbd1b9370d91b37442d151ec17`; source size 1704×923; grid 2x3; Pillow info keys: none; metadata audit: inspect_file.py found C2PA/AI metadata in a caBX PNG chunk; ExifTool identified C2PA JUMBF labels..
- Frames: 6; final canvas 384×208; extraction report: `{'ok': True, 'frames_root': '[session scratch, not kept]/art/anim/.work/extracted/wolf/idle', 'states': ['idle']}`; inspect report: `{'ok': True, 'frames_root': '[session scratch, not kept]/art/anim/.work/extracted/wolf/idle', 'states': ['idle'], 'errors': [], 'warnings': ['idle used extraction method stable-slots; component extraction is preferred']}`.
- Anchor: silhouette-torso-proxy; fixed target mean [192.0, 163.48] px; maximum frame-to-frame drift 0.71 px.
- Visible character bounds (width min/median/max × height min/median/max): [168, 170.0, 176] × [90, 91.0, 92] px; target height/length 170 px.
- Foot baseline: y=198; max support-frame deviation 0 px after snapping; per-frame snap adjustments {'0': 1, '1': 1, '2': 0, '3': 0, '4': 0, '5': 0}; non-support/flight foot bottoms {}.
- Loop seam (last→first): silhouette IoU 0.9541; RGBA mean absolute pixel difference 2.031; first/last alpha bounds [98, 108, 266, 198] / [98, 107, 267, 198].
- Contact indices by foot: `{"left_fore": [0, 1, 2, 3, 4, 5], "left_hind": [0, 1, 2, 3, 4, 5], "right_fore": [0, 1, 2, 3, 4, 5], "right_hind": [0, 1, 2, 3, 4, 5]}`.
- Contact QA: All four paws remain grounded in all six idle frames; these indices describe stance, not sound triggers.
- Worker QA: Pass for six right-facing frames, grey-blue armor and cyan lights, exactly two ears, four articulated legs and segmented tail, common grounded paws, flat key and small breathing/ear/tail motion.
- Outputs: right `wolf/idle/frame_00.png` … `wolf/idle/frame_05.png`; mirrored `wolf/idle-left/frame_00.png` … `wolf/idle-left/frame_05.png`; sheet `wolf/idle-sheet.png`.

#### Prompt used for selected source

```text
Painterly 2D side-view sci-fi horror game sprite row for WOLF//OVERRIDE. Generate exactly 6 sequential full-body frames of WOLF, a robotic wolf facing screen-right and standing in place. Image 1 is the canonical identity reference; match the same head and muzzle, grey-blue armour plating, cyan eye and seam lights, proportions, four articulated legs, and segmented tail. Keep exactly two ears, four legs, and the same tail segments in every frame. Image 2 is lighting/rendering style only: cool blue-black cinematic edge light and textured painterly metal; do not include a corridor or environment. Image 3 is a layout-only 2-column by 3-row guide; read left-to-right, then continue on the next row. Ignore its guide lines and colors.

Each equal cell is landscape 384:208, one complete wolf pose, same character scale, with the torso/hip assembly centered on a fixed anchor. Keep all four paws resting on one shared baseline in every frame. Sequence: 00 neutral; 01 subtle body inhale; 02 small chest rise; 03 one ear makes a small twitch while both ears remain present; 04 slow tail sway; 05 return to the neutral pose of 00. Breathing, one small ear twitch, and slow tail sway only; no walking or lifted paws. Make frame 05 meet frame 00 smoothly.

Use a perfectly flat, uniform #00FF00 chroma-key background in every cell. No scenery, floor, ground plane, shadows, motion lines, text, labels, cell borders, guide marks, duplicated panels, detached effects, or glow outside the body. Keep the full wolf inside each cell with clear gaps between poses.
```

### wolf/walk

- Source: `[Codex generated-images store]/01a12765-f53e-7213-befe-e5a3a60c54d5/exec-11b1c0ed-7dcd-4dd9-8ee1-9c288e68112d.png`; SHA-256 `a043e6ed6285476a9bcf9d3d125eed46cf4971a49d765a2a6902d697faa2dbb2`; source size 1703×924; grid 2x4; Pillow info keys: none; metadata audit: inspect_file.py found C2PA/AI metadata in a caBX PNG chunk; ExifTool identified C2PA JUMBF labels..
- Frames: 8; final canvas 384×208; extraction report: `{'ok': True, 'frames_root': '[session scratch, not kept]/art/anim/.work/extracted/wolf/walk', 'states': ['running-right']}`; inspect report: `{'ok': True, 'frames_root': '[session scratch, not kept]/art/anim/.work/extracted/wolf/walk', 'states': ['running-right'], 'errors': [], 'warnings': ['running-right used extraction method stable-slots; component extraction is preferred']}`.
- Anchor: silhouette-torso-proxy; fixed target mean [192.07, 169.97] px; maximum frame-to-frame drift 1.05 px.
- Visible character bounds (width min/median/max × height min/median/max): [166, 170.0, 170] × [71, 74.5, 75] px; target height/length 170 px.
- Foot baseline: y=198; max support-frame deviation 0 px after snapping; per-frame snap adjustments {'0': 0, '1': 0, '2': 0, '3': 0, '4': 1, '5': 1, '6': 2, '7': 2}; non-support/flight foot bottoms {}.
- Loop seam (last→first): silhouette IoU 0.8497; RGBA mean absolute pixel difference 2.841; first/last alpha bounds [99, 123, 265, 198] / [98, 127, 266, 198].
- Contact indices by foot: `{"left_fore": [2], "left_hind": [0], "right_fore": [6], "right_hind": [4]}`.
- Contact QA: UNVERIFIED: indices 00/02/04/06 are the prompted left-hind, left-fore, right-hind, right-fore sequence. The final side-view retry does not let workers distinguish individual near-side/far-side touchdown frames.
- Worker QA: Identity, anatomy, frame count and key pass. Exact per-foot touchdown sequence FAILS worker QA: the generated side view shows multiple paws near the baseline in frames 00/02/04/06 and does not distinguish near-side from far-side attribution. Contact indices listed here are the prompt's intended sequence, not certified contacts.
- Outputs: right `wolf/walk/frame_00.png` … `wolf/walk/frame_07.png`; mirrored `wolf/walk-left/frame_00.png` … `wolf/walk-left/frame_07.png`; sheet `wolf/walk-sheet.png`.

#### Prompt used for selected source

```text
Painterly 2D side-view sci-fi horror game sprite row for WOLF//OVERRIDE. Generate exactly 8 sequential full-body frames of a correct four-beat quadruped walk, with WOLF facing and travelling screen-right in place. Image 1 is the canonical identity reference; match the same head and muzzle, grey-blue armour plating, cyan eye and seam lights, proportions, four articulated legs, and segmented tail. Keep exactly two ears, four legs, and the same tail segments in every frame. Image 2 is lighting/rendering style only: cool blue-black cinematic edge light and textured painterly metal; do not include a corridor or environment. Image 3 is a layout-only 2-column by 4-row guide; read left-to-right, then continue on the next row. Ignore its guide lines and colors.

Each equal cell is landscape 384:208, one complete wolf pose, same character scale, with the torso/hip assembly centered on a fixed anchor. All paws stay at or above one shared baseline; each contact paw touches it exactly. Four-beat lateral sequence: 00 left hind paw contact; 01 transition; 02 left fore paw contact; 03 transition; 04 right hind paw contact; 05 transition; 06 right fore paw contact; 07 transition, returning smoothly to 00. Left and right mean WOLF's anatomical sides. Keep at least two paws supporting the body, with no flight phase. Tail balances the walk without changing its segment count.

Use a perfectly flat, uniform #00FF00 chroma-key background in every cell. No scenery, floor, ground plane, shadows, motion lines, text, labels, cell borders, guide marks, duplicated panels, detached effects, or glow outside the body. Keep the full wolf inside each cell with clear gaps between poses.

Final retry constraints: Use a strict orthographic side profile of WOLF's left flank: the near-camera limbs are WOLF's left legs, and the far-side limbs are WOLF's right legs, offset slightly upward so every paw is visible separately. Hind paws stay under the rear half of the torso; fore paws stay under the front half. Make the named sole contacts unmistakable: frame 00 near left hind, frame 02 near left fore, frame 04 far right hind, frame 06 far right fore, each sole exactly on the shared baseline. Keep other paws supporting; no flight. Never merge or hide a paw, and keep the body anchor fixed.
```

### wolf/trot

- Source: `[Codex generated-images store]/01a12766-03d5-7e43-b57e-aaf86de31faa/exec-174d9021-60b6-42a9-ac57-786cb1decb7e.png`; SHA-256 `87fdd442121a5b5c295c292699bd0e29d86c58595099c9da35771d02d3f13e03`; source size 1703×924; grid 2x4; Pillow info keys: none; metadata audit: inspect_file.py found C2PA/AI metadata in a caBX PNG chunk; ExifTool identified C2PA JUMBF labels..
- Frames: 8; final canvas 384×208; extraction report: `{'ok': True, 'frames_root': '[session scratch, not kept]/art/anim/.work/extracted/wolf/trot', 'states': ['running-right']}`; inspect report: `{'ok': True, 'frames_root': '[session scratch, not kept]/art/anim/.work/extracted/wolf/trot', 'states': ['running-right'], 'errors': [], 'warnings': ['running-right used extraction method stable-slots; component extraction is preferred']}`.
- Anchor: silhouette-torso-proxy; fixed target mean [192.03, 170.08] px; maximum frame-to-frame drift 2.1 px.
- Visible character bounds (width min/median/max × height min/median/max): [166, 170.0, 180] × [62, 73.5, 76] px; target height/length 170 px.
- Foot baseline: y=198; max support-frame deviation 0 px after snapping; per-frame snap adjustments {'0': 0, '1': 0, '2': 0, '4': -1, '5': -1, '6': 2}; non-support/flight foot bottoms {'3': 196, '7': 194}.
- Loop seam (last→first): silhouette IoU 0.5738; RGBA mean absolute pixel difference 5.204; first/last alpha bounds [99, 124, 265, 198] / [91, 132, 271, 194].
- Contact indices by foot: `{"flight": [3, 7], "left_fore": [0], "left_hind": [4], "right_fore": [4], "right_hind": [0]}`.
- Contact QA: UNVERIFIED: indices 00 and 04 are the prompted diagonal pairs. Workers cannot certify anatomical pairing from this side view; measured lowest paw pixels at 03/07 are y=196/194 against baseline y=198, so those frames do not show clear flight.
- Worker QA: Identity, anatomy, frame count and key pass. Worker sees suspension poses at 03/07 but cannot certify 12 px clearance or assign the exact anatomical diagonal pairs from the side view. Contact indices and flight frames listed here are the intended prompt sequence; exact per-foot contact QA remains unverified.
- Outputs: right `wolf/trot/frame_00.png` … `wolf/trot/frame_07.png`; mirrored `wolf/trot-left/frame_00.png` … `wolf/trot-left/frame_07.png`; sheet `wolf/trot-sheet.png`.

#### Prompt used for selected source

```text
Painterly 2D side-view sci-fi horror game sprite row for WOLF//OVERRIDE. Generate exactly 8 sequential full-body frames of a diagonal-pair quadruped trot, with WOLF facing and travelling screen-right in place. Play at 12 fps with stride amplitude that reads as about two body lengths per second. Image 1 is the canonical identity reference; match the same head and muzzle, grey-blue armour plating, cyan eye and seam lights, proportions, four articulated legs, and segmented tail. Keep exactly two ears, four legs, and the same tail segments in every frame. Image 2 is lighting/rendering style only: cool blue-black cinematic edge light and textured painterly metal; do not include a corridor or environment. Image 3 is a layout-only 2-column by 4-row guide; read left-to-right, then continue on the next row. Ignore its guide lines and colors.

Each equal cell is landscape 384:208, one complete wolf pose, same character scale, with the torso/hip assembly centered on a fixed anchor. Contact frames touch one shared baseline exactly. Sequence: 00 left fore plus right hind diagonal contact; 01 compression; 02 gather and swing; 03 clear suspension with all four paws above the baseline; 04 right fore plus left hind diagonal contact; 05 compression; 06 gather and swing; 07 clear suspension with all four paws above the baseline, returning smoothly to 00. Left and right mean WOLF's anatomical sides. Keep the trot controlled and springy, not a gallop or sprint; the segmented tail balances the motion.

Use a perfectly flat, uniform #00FF00 chroma-key background in every cell. No scenery, floor, ground plane, shadows, motion lines, dust, text, labels, cell borders, guide marks, duplicated panels, detached effects, or glow outside the body. Keep the full wolf inside each cell with clear gaps between poses.

Final retry constraints: Use an orthographic side profile of WOLF's left flank. The near-camera limbs are WOLF's left legs; the far-side right legs are offset slightly upward and behind so all four paws remain separately visible. At frame 00, both left fore (near front) and right hind (far rear) soles touch the shared baseline as a clear diagonal pair. At frame 04, both right fore (far front) and left hind (near rear) soles touch the baseline as the opposite diagonal pair. Frames 03 and 07 are clear suspension poses with all four paws at least 12 px above the baseline. All other stances preserve the correct diagonal-pair trot, fixed torso anchor, consistent scale, and right-facing profile.
```

## Output inventory

- `anim/engineer/idle/frame_00.png` … `frame_05.png` — right-facing idle sequence.
- `anim/engineer/idle-left/frame_00.png` … `frame_05.png` — mirrored left-facing idle sequence, original frame order retained.
- `anim/engineer/idle-sheet.png` — right-facing frames in one horizontal strip.
- `anim/engineer/idle-left/sheet.png` — mirrored frames in one horizontal strip.
- `anim/previews/engineer-idle-1x.gif` — 256×384 looping 6-frame preview at 8.0 fps; durations [120, 130, 120, 130, 120, 130] ms.
- `anim/previews/engineer-idle-1x.webp` — 256×384 looping 6-frame preview at 8.0 fps; durations [125, 125, 125, 125, 125, 125] ms.
- `anim/previews/engineer-idle-2x.gif` — 512×768 looping 6-frame preview at 8.0 fps; durations [120, 130, 120, 130, 120, 130] ms.
- `anim/previews/engineer-idle-2x.webp` — 512×768 looping 6-frame preview at 8.0 fps; durations [125, 125, 125, 125, 125, 125] ms.
- `anim/engineer/walk/frame_00.png` … `frame_07.png` — right-facing walk sequence.
- `anim/engineer/walk-left/frame_00.png` … `frame_07.png` — mirrored left-facing walk sequence, original frame order retained.
- `anim/engineer/walk-sheet.png` — right-facing frames in one horizontal strip.
- `anim/engineer/walk-left/sheet.png` — mirrored frames in one horizontal strip.
- `anim/previews/engineer-walk-1x.gif` — 256×384 looping 8-frame preview at 11.94 fps; durations [80, 90, 80, 90, 80, 80, 90, 80] ms.
- `anim/previews/engineer-walk-1x.webp` — 256×384 looping 8-frame preview at 11.99 fps; durations [83, 83, 84, 83, 83, 84, 83, 84] ms.
- `anim/previews/engineer-walk-2x.gif` — 512×768 looping 8-frame preview at 11.94 fps; durations [80, 90, 80, 90, 80, 80, 90, 80] ms.
- `anim/previews/engineer-walk-2x.webp` — 512×768 looping 8-frame preview at 11.99 fps; durations [83, 83, 84, 83, 83, 84, 83, 84] ms.
- `anim/engineer/jog/frame_00.png` … `frame_07.png` — right-facing jog sequence.
- `anim/engineer/jog-left/frame_00.png` … `frame_07.png` — mirrored left-facing jog sequence, original frame order retained.
- `anim/engineer/jog-sheet.png` — right-facing frames in one horizontal strip.
- `anim/engineer/jog-left/sheet.png` — mirrored frames in one horizontal strip.
- `anim/previews/engineer-jog-1x.gif` — 256×384 looping 8-frame preview at 11.94 fps; durations [80, 90, 80, 90, 80, 80, 90, 80] ms.
- `anim/previews/engineer-jog-1x.webp` — 256×384 looping 8-frame preview at 11.99 fps; durations [83, 83, 84, 83, 83, 84, 83, 84] ms.
- `anim/previews/engineer-jog-2x.gif` — 512×768 looping 8-frame preview at 11.94 fps; durations [80, 90, 80, 90, 80, 80, 90, 80] ms.
- `anim/previews/engineer-jog-2x.webp` — 512×768 looping 8-frame preview at 11.99 fps; durations [83, 83, 84, 83, 83, 84, 83, 84] ms.
- `anim/wolf/idle/frame_00.png` … `frame_05.png` — right-facing idle sequence.
- `anim/wolf/idle-left/frame_00.png` … `frame_05.png` — mirrored left-facing idle sequence, original frame order retained.
- `anim/wolf/idle-sheet.png` — right-facing frames in one horizontal strip.
- `anim/wolf/idle-left/sheet.png` — mirrored frames in one horizontal strip.
- `anim/previews/wolf-idle-1x.gif` — 384×208 looping 6-frame preview at 8.0 fps; durations [120, 130, 120, 130, 120, 130] ms.
- `anim/previews/wolf-idle-1x.webp` — 384×208 looping 6-frame preview at 8.0 fps; durations [125, 125, 125, 125, 125, 125] ms.
- `anim/previews/wolf-idle-2x.gif` — 768×416 looping 6-frame preview at 8.0 fps; durations [120, 130, 120, 130, 120, 130] ms.
- `anim/previews/wolf-idle-2x.webp` — 768×416 looping 6-frame preview at 8.0 fps; durations [125, 125, 125, 125, 125, 125] ms.
- `anim/wolf/walk/frame_00.png` … `frame_07.png` — right-facing walk sequence.
- `anim/wolf/walk-left/frame_00.png` … `frame_07.png` — mirrored left-facing walk sequence, original frame order retained.
- `anim/wolf/walk-sheet.png` — right-facing frames in one horizontal strip.
- `anim/wolf/walk-left/sheet.png` — mirrored frames in one horizontal strip.
- `anim/previews/wolf-walk-1x.gif` — 384×208 looping 8-frame preview at 11.94 fps; durations [80, 90, 80, 90, 80, 80, 90, 80] ms.
- `anim/previews/wolf-walk-1x.webp` — 384×208 looping 8-frame preview at 11.99 fps; durations [83, 83, 84, 83, 83, 84, 83, 84] ms.
- `anim/previews/wolf-walk-2x.gif` — 768×416 looping 8-frame preview at 11.94 fps; durations [80, 90, 80, 90, 80, 80, 90, 80] ms.
- `anim/previews/wolf-walk-2x.webp` — 768×416 looping 8-frame preview at 11.99 fps; durations [83, 83, 84, 83, 83, 84, 83, 84] ms.
- `anim/wolf/trot/frame_00.png` … `frame_07.png` — right-facing trot sequence.
- `anim/wolf/trot-left/frame_00.png` … `frame_07.png` — mirrored left-facing trot sequence, original frame order retained.
- `anim/wolf/trot-sheet.png` — right-facing frames in one horizontal strip.
- `anim/wolf/trot-left/sheet.png` — mirrored frames in one horizontal strip.
- `anim/previews/wolf-trot-1x.gif` — 384×208 looping 8-frame preview at 11.94 fps; durations [80, 90, 80, 90, 80, 80, 90, 80] ms.
- `anim/previews/wolf-trot-1x.webp` — 384×208 looping 8-frame preview at 11.99 fps; durations [83, 83, 84, 83, 83, 84, 83, 84] ms.
- `anim/previews/wolf-trot-2x.gif` — 768×416 looping 8-frame preview at 11.94 fps; durations [80, 90, 80, 90, 80, 80, 90, 80] ms.
- `anim/previews/wolf-trot-2x.webp` — 768×416 looping 8-frame preview at 11.99 fps; durations [83, 83, 84, 83, 83, 84, 83, 84] ms.
- `anim/engineer-contact-sheet.png` — all three rows, right-facing and mirrored.
- `anim/wolf-contact-sheet.png` — all three rows, right-facing and mirrored.

## Metadata removal

`inspect_file.py` flagged all six selected source PNGs as containing C2PA/AI metadata in a `caBX` chunk (ExifTool identified C2PA JUMBF labels); Pillow's `Image.info` did not expose that chunk. Final frames, strips, contact sheets, GIFs, and WebPs were re-encoded by Pillow without copying the source chunk. Pixel-domain marks and soft-binding were not evaluated. The prompt text in this QA file is preserved verbatim.
