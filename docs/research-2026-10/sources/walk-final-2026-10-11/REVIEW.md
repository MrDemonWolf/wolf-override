# walk3 independent art review (2026-10-11)

**Verdict: fix needed.** The motion numbers check out. Five fixes remain, and four of them need a regrade, a shift or a small retouch, not a full new pose. Nothing here was played or imported into Godot, so this review makes no claims about feel. Numbers are in cell px, with 1080p game px in brackets (engineer ×0.6859, WOLF ×0.7029).

## What I checked
- **Bible QA.** I ran `art-audit/bible/qa_asset.py` on every delivered row. As a baseline, I also ran it on the approved walk2 rows and the hq design sheets. Output is in `review/qa/` and `review/qa-walk2/`.
- **Motion.** I re-ran `measure2.py` and `soles.py` on copies of the delivered sprites, in an isolated copy under `review/remeasure/`. The authors' outputs were not touched.
- **Colour.** I measured plate colour with `wolf/tools/colour.py` and counted cyan and magenta pixels with `review/cyan.py`.
- **By eye.** I looked at every sheet, the before/after sheets, the stills and the clip stills. My crops are in `review/view/`.

## Results that pass
- **Motion reproduces exactly.**
  - Eng jog: torso 1.90 (1.30), head 0.19, guide slide 0.61, sole slide 0.23, gap 7 at frame 10.
  - Eng walk: torso 0.73, guide slide 0.32, sole slide 1.42, gap 3.
  - Eng idle: unchanged.
  - WOLF walk: guide slide 3.00, soles 1.55, withers drift 2.55.
  - WOLF trot: guide slide 1.16, soles 4.07, withers drift 2.92.
  - Playback fps re-derived from world speed × 2.7 ÷ (stride × scale): 15.30, 22.83, 19.76 and 29.83, matching loops.json and the webp frame delays.
- **Identity.** In every row it is the same character in every frame. I found no added gear. The engineer keeps the red hooded jacket, charcoal trousers, boots, harness and cyan belt light. WOLF stays fully robotic, with cyan eye and seams.
- **WOLF regrade.** The idle, walk and trot plates now sit at hue 254–263°, a* about −1. The approved stand is 258°, a* −1.4; walk2 was 207°, a* −5.9.
- **Scale and baseline.** Every set uses one canvas per row. The sprite baseline is 311 (engineer) and 263 (WOLF), with spread 0–4. Jog frames 5, 6 and 11 sit at 288–310 because they are flight frames, which is expected.
- **Context clip.** The engineer frames in the WOLF context clip are byte-identical to the final `engineer/sprites`.
- **Metadata.** All 25 new raws check out on every point:
  - Each SHA-256 matches its provenance line and its source in `~/.codex/generated_images`.
  - Each carries a C2PA manifest (JUMBF `c2pa`; actions created, converted, watermarked).
  - Each session is archived and none are still active.
  - The delivered sprites are derived crops, so they carry no C2PA, which is expected.

## Fix list (exact frames)
1. **WOLF death poses use the old, ungraded teal colour: liedown 0–3, lookaway 0 and lookaway-alt 0–1.**
   - Plate hue is 207–226° and a* −4.5 to −5.9, against 254–263° for the walk3 rows.
   - Liedown frame 0 is byte-identical to the walk2 idle frame_00, not the walk3 one.
   - In play, WOLF would change colour when the death screen starts.
   - **Fix (no repaint):** apply `wolf/qa/colour/grade.json` with `grade.py` to every WOLF death frame, swap in the walk3 `wolf-idle/frame_00` padded to 640, then re-render the previews and stills.
2. **Eng walk frames 1 and 2: the boots sink into the floor.**
   - Contact gap is −2 (far foot, frame 1) and −3 (near foot, frame 2). The lowest opaque row is 313 and 314, against 311 in walk2. That is 1.4–2.1 game px below the floor.
   - This came from the new sheet-scale registration.
   - **Fix:** shift both frames up 2–3 px, or re-seat the soles, then re-measure.
3. **Eng walk frame 2: the forward-swinging far hand is a dark, shapeless smudge.**
   - In frames 0 and 1 the same glove shows detail and value, so it will pop for one frame.
   - Frames 1 and 2 also have warmer greys: b* +0.33 and +0.19, against −1.7 to −2.3 in the other ten frames (the bible limit is ≤ −1).
   - Their edge colour shift is 6.05 and 6.21, against 3.5–4.7 in the other frames.
   - **Fix:** retouch the far glove in frame 2 to match frame 1, then match frames 1–2 neutrals to frames 0 and 3.
4. **WOLF trot frame 0, the whole-frame aF repaint: dark outline and missing rim.**
   - It is the only trot frame that fails the no-dark-outline rule: outline dL −8.7, against −1.2 to −4.9 in the other frames (limit −8).
   - Its top light is 20.0, against 24–33 in the other frames.
   - It has 2011 cyan px, against 2408–3052 in the other frames. By eye, the cyan rim along the back and tail is missing at the 11→0→1 seam.
   - **Fix:** keep aF's legs and composite the body and tail from an approved frame (as `composite.py` already does), or repaint the body rendering only.
5. **Eng jog frame 6 (minor).**
   - Its greys are warmer (b* −2.41, against −3.7 to −5.4 in the other frames).
   - Its edge colour shift is 8.05, the highest in the row (4.2–5.8 in the other frames).
   - There is a 9 px magenta fleck at the trailing ankle.
   - **Fix:** colour-match the frame and run a despill pass.

## Inherited from approved walk2 (not regressions; for awareness)
- In every row, including walk2, the dark and halo fringe shares are 0.09–0.24, above the bible's 0.10.
- WOLF accent dE p90 is 18–23, against a limit of 18.
- In the trot, the near hind skates in frames 8–11, and frames 7–8 have the LH paw 3 px below the floor.
- WOLF idle head drift is 5.8 cell px. It was 5.8 in walk2 too.
- WOLF idle has a 15 px contact gap.

## Notes on the death stills
- **Lying length.** The engineer's lying pose is 323 cell px long, which is 1.17× the standing 277. Judge it beside the walk rows in game.
- **Honest still.** WOLF is by far the brightest thing on screen, while the drained engineer barely reads.
- **Pressed still.** The engineer's head touches the sentry treads. That can read as crushed, so move one of them a few px. This is layout, not a sprite fix.

## Best previews
- `engineer/deliver/beforeafter/eng-jog-frame-6.png`
- `engineer/deliver/beforeafter/eng-walk-frames-1-2.png`
- `wolf/deliver/beforeafter/colour-before-after.png`
- `wolf/deliver/beforeafter/slips-before-after.png`
- `wolf/deliver/context/context-720p30.webp` and `still-260.png`
- `death-poses/deliver/previews/eng-collapse-2x-strip.png`
- `death-poses/deliver/stills/look-a-blast-honest-1080p.png`
- `review/view/trot-11-00-01.png` (fix 4)
- `review/view/eng-walk-0123.png` (fixes 2 and 3)

## Not done
The relayed request to have Codex update Notion and the Codex board is still open. This review touched no Git checkout, Notion or board.

---

# Round 2: independent re-review of the six fixes (2026-10-11)

**Verdict: pass.** All six fixes are done and I found no regression in identity, colour, baseline, motion or metadata. This was headless measurement, bible QA, and looking at sprites, sheets, clip stills and the two death stills. Nothing was imported into Godot or played, so this round makes no feel claims either. My working files are in `review/r2/` (`qa/`, `rm-engineer/`, `rm-wolf/`, `view/`).

## Scope check
- A byte diff against `fix/prev/` shows that only the targeted frames changed:
  - eng-walk 1–2 and eng-jog 6.
  - wolf-trot 0.
  - wolf-liedown 0–3, wolf-lookaway 0 and wolf-lookaway-alt 0–1.
  - The sheets and `rows-info.json` were rebuilt.
- Every other frame is byte-identical. The eng rows inside `wolf/deliver/sprites` match `engineer/deliver/sprites`.

## Each fix, re-measured
1. **WOLF death colour: done.**
   - Plate hue is now 254–262°, with a* −1.05 to −1.65 (`wolf/tools/colour.py`). The walk3 walk and trot frame 0 measure 260–261°.
   - Liedown frame 0 is pixel-identical to the walk3 `wolf-idle/frame_00` at x offset 64, with an empty pad.
   - In bible QA, cool neutrals moved to b* −4.4 to −5.4, in line with the trot row. The outline pass holds (−1.7 to −4.0), and the baseline spread is 1.
   - The sheet matches the walk3 reference by eye.
2. **Eng walk boots: done.**
   - The lowest row is 311 in frames 1 and 2. The set's baseline spread went from 4 to 1, and the contact gap max went from 3 to 1.
   - On my crops with a floor line, every boot sits on the line, and the lifted trailing toe in frame 1 is not visibly distorted.
   - Motion reproduces: torso 0.72, head 0.12, guide slide 0.38 (best fit 20.62), sole slide 1.42 / p90 0.98, hcv 0.0087.
3. **Eng walk frame 2 far hand and greys: done.**
   - The smudge is gone with no ghost. The glove now matches frame 1 in detail and value.
   - The far hand moves back steadily across frames 1, 2 and 3 (`view/walk-hand-0to3.png`).
   - Frame 1: b* −1.87, edge shift 4.60. Frame 2: b* −1.80, edge shift 4.30. Both are inside the row.
   - Outline and top light are within the row (frame 2 top light 11.2).
4. **WOLF trot frame 0: done.**
   - Outline is −6.8, which passes (limit −8). Top light is 24.7, and there are 2260 cyan px.
   - The rim on the back and tail is back at the 11→0→1 seam.
   - The feathered body/leg cut is not visible at 3× (`view/trot0-joins.png`).
   - Unchanged: guide slide 1.16, soles 4.07, withers drift 2.92, gap 3. Seam IoU went from 0.633 to 0.643.
5. **Eng jog frame 6: done.**
   - b* is −4.96 and edge shift 4.42, both inside the row. Magenta is down from 9 to 2 px; the 2 left are hair pixels at (138–139, 73–74), and the ankle fleck is gone.
   - Shape and every motion number are unchanged.
   - Its trousers now match frames 5 and 7 by eye.
6. **Stills: done.**
   - Pressed: the sentry treads are clearly clear of the engineer's head.
   - Honest: the soft cyan rim shows on the engineer's legs and hands. WOLF's eye keeps its cyan in both stills.
   - Text contrast in `stills/metrics.json` stays at 8.9:1 or better for the worst pixel.

## Regression checks
- **Identity.** The same characters and gear appear in every changed frame, and nothing was added. The engineer is drawn the same throughout.
- **Playback.** The fps in `loops.json` are unchanged: 15.30, 22.83, 19.76 and 29.83. Loops, context clips and previews were all rebuilt after the fix.
- **Metadata.**
  - All 25 recorded walk3 raw SHA-256 values still match a raw file, and each one still carries its C2PA (`c2pa` JUMBF).
  - The only raw-folder edits are the appended "derived" lines in the three provenance files.
  - Codex wrote 9 images after round 1. They belong to two other sessions, and none of them was copied into walk3, which confirms there were no new generations.
- **Git.** The checkout is untouched (clean at `76d3a50`).

## Minor notes (not blocking)
- **Trot frame 0 edges.**
  - Halo share is 0.247, against 0.17–0.21 for the other trot frames. Every frame of this row was already over the bible's 0.10, as inherited from walk2.
  - It also has 98 interior px below alpha 255. All but two small patches are 253–254, which cannot be seen. The 18 px patch down to 145 sits on the belly/thigh notch at the silhouette edge, not inside the body.
- **Head drift.** Trot head drift is now 1.06 (0.75 game px), at the 11→0 seam.
- **Unchanged frames.** The untouched approved frames still carry the magenta flecks the fixer reported (walk 0 and 4, jog 7) and the inherited walk2 items listed above.

## Best previews (round 2)
- `engineer/deliver/beforeafter/fix-eng-walk-frames-1-2.png`
- `engineer/deliver/beforeafter/fix-eng-jog-frame-6.png`
- `wolf/deliver/beforeafter/fix-wolf-trot-frame-0.png`
- `death-poses/deliver/beforeafter/wolf-death-colour-before-after.png`
- `death-poses/deliver/beforeafter/stills-before-after.png`
- `review/r2/view/trot-seam-r2.png`
- `review/r2/view/walk-hand-0to3.png`

## Still open
The relayed request for Codex to update Notion and the Codex board has not been run. Neither round touched Notion or the board.
